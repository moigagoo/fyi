import React, { Component } from "react";
import axios from "axios";
import "./App.css";
import {
  Table,
  Input,
  Button,
  Popconfirm,
  Form,
  notification,
  Drawer,
  Icon,
  Alert
} from "antd";
import ReactMarkdown from "react-markdown";

const FormItem = Form.Item;
const EditableContext = React.createContext();
const { TextArea } = Input;

const EditableRow = ({ form, index, ...props }) => (
  <EditableContext.Provider value={form}>
    <tr {...props} />
  </EditableContext.Provider>
);

function hasErrors(fieldsError) {
  return Object.keys(fieldsError).some(field => fieldsError[field]);
}

const EditableFormRow = Form.create()(EditableRow);

class EditableCell extends React.Component {
  state = {
    editing: false
  };

  componentDidMount() {
    if (this.props.editable) {
      document.addEventListener("click", this.handleClickOutside, true);
    }
  }

  componentWillUnmount() {
    if (this.props.editable) {
      document.removeEventListener("click", this.handleClickOutside, true);
    }
  }

  toggleEdit = () => {
    const editing = !this.state.editing;
    this.setState({ editing }, () => {
      if (editing) {
        this.input.focus();
      }
    });
  };

  handleClickOutside = e => {
    const { editing } = this.state;
    if (editing && this.cell !== e.target && !this.cell.contains(e.target)) {
      this.save();
    }
  };

  save = () => {
    const { record, handleSave } = this.props;
    this.form.validateFields((error, values) => {
      if (error) {
        return;
      }
      this.toggleEdit();
      handleSave({ ...record, ...values });
    });
  };

  render() {
    const { editing } = this.state;
    const {
      editable,
      dataIndex,
      title,
      record,
      index,
      handleSave,
      ...restProps
    } = this.props;
    return (
      <td ref={node => (this.cell = node)} {...restProps}>
        {editable ? (
          <EditableContext.Consumer>
            {form => {
              this.form = form;
              return editing ? (
                <FormItem style={{ margin: 0 }}>
                  {form.getFieldDecorator(dataIndex, {
                    rules: [
                      {
                        required: true,
                        message: `${title} is required.`
                      }
                    ],
                    initialValue: record[dataIndex]
                  })(
                    <TextArea
                      ref={node => (this.input = node)}
                      onPressEnter={this.save}
                      autosize
                    />
                  )}
                </FormItem>
              ) : (
                <pre
                  className="editable-cell-value-wrap"
                  style={{ paddingRight: 24 }}
                  onClick={this.toggleEdit}
                >
                  <ReactMarkdown
                    source={restProps.children[2]}
                    renderers={{
                      code: ({ value }) => {
                        return <Alert message={value} type="info" />;
                      }
                    }}
                  />
                </pre>
              );
            }}
          </EditableContext.Consumer>
        ) : (
          restProps.children
        )}
      </td>
    );
  }
}

class App extends Component {
  constructor(props) {
    super(props);
    this.columns = [
      {
        title: "Id",
        dataIndex: "id"
      },
      {
        title: "Text",
        dataIndex: "body",
        editable: true
      },
      {
        title: "Rating",
        dataIndex: "rating"
      },
      {
        title: "Created",
        dataIndex: "createdAt"
      },
      {
        title: "Action",
        dataIndex: "operation",
        width: 100,
        render: (text, record) =>
          this.state.dataSource.length >= 1 ? (
            <div style={{ width: 100 }}>
              <Popconfirm
                title="Sure to delete?"
                onConfirm={() => this.handleDelete(record.id)}
              >
                <a href="javascript:;">Delete</a>
              </Popconfirm>
            </div>
          ) : null
      }
    ];

    this.state = {
      search: "",
      dataSource: [],
      drawerVisible: false
    };
  }

  componentDidMount() {
    this.getAllEntries();
  }

  getAllEntries() {
    this.setState({ loading: true });
    axios.get("/api/entries").then(response => {
      this.setState({ dataSource: response.data, loading: false });
    });
  }

  handleDelete = id => {
    const dataSource = [...this.state.dataSource];
    this.setState({ dataSource: dataSource.filter(item => item.id !== id) });
    axios
      .delete(`/api/entries/${id}`)
      .then(() => {
        notification.success({
          message: "УДОЛИЛ!"
        });
      })
      .catch(() => {
        notification.error({
          message: "чот пошло не так!"
        });
      });
  };

  handleSave = row => {
    const newData = [...this.state.dataSource];
    const index = newData.findIndex(item => row.id === item.id);
    const item = newData[index];
    newData.splice(index, 1, {
      ...item,
      ...row
    });
    this.setState({ dataSource: newData });
    axios
      .put(`/api/entries/${row.id}`, { text: row.body })
      .then(() => {
        notification.success({
          message: "СОХРОНИЛ!"
        });
      })
      .catch(() => {
        notification.error({
          message: "чот пошло не так!"
        });
      });
  };

  handleSearch = e => {
    this.setState({ search: e.target.value });
  };

  showDrawer = () => {
    this.setState({
      drawerVisible: true
    });
  };

  hideDrawer = () => {
    this.setState({
      drawerVisible: false
    });
  };

  handleSubmit = e => {
    e.preventDefault();
    this.props.form.validateFields((err, values) => {
      if (!err) {
        this.hideDrawer();
        axios
          .post("/api/entries/", { text: values.text })
          .then(() => {
            notification.success({
              message: "СОЗДОЛОСЬ!"
            });
            this.getAllEntries();
          })
          .catch(() => {
            notification.error({
              message: "чот пошло не так!"
            });
          });
      }
    });
  };

  render() {
    const { dataSource, search } = this.state;
    const {
      getFieldDecorator,
      getFieldsError,
      getFieldError,
      isFieldTouched
    } = this.props.form;

    const textError = getFieldError("text");

    const components = {
      body: {
        row: EditableFormRow,
        cell: EditableCell
      }
    };
    const columns = this.columns.map(col => {
      if (!col.editable) {
        return col;
      }
      return {
        ...col,
        onCell: record => ({
          record,
          editable: col.editable,
          dataIndex: col.dataIndex,
          title: col.title,
          handleSave: this.handleSave
        })
      };
    });

    const filteredDataSource = dataSource.filter(ds => {
      return ds.body.includes(search);
    });

    const sortedDataSource = filteredDataSource.sort((a, b) => {
      return new Date(b.createdAt) - new Date(a.createdAt);
    });

    return (
      <div className="app">
        <div className="search">
          <Input
            onChange={this.handleSearch}
            value={search}
            size="large"
            placeholder="Search"
          />
        </div>
        <Table
          rowKey="id"
          components={components}
          rowClassName={() => "editable-row"}
          bordered
          dataSource={sortedDataSource}
          columns={columns}
          loading={this.state.loading}
        />
        <Button type="primary" onClick={this.showDrawer}>
          КРИЭЙТ!
        </Button>
        <Drawer
          width={640}
          title="СОЗДАЙ"
          placement="right"
          closable={false}
          onClose={this.hideDrawer}
          visible={this.state.drawerVisible}
        >
          <Form onSubmit={this.handleSubmit}>
            <Form.Item
              validateStatus={textError ? "error" : ""}
              help={textError || ""}
            >
              {getFieldDecorator("text", {
                rules: [
                  {
                    required: true,
                    message: "Ну ты введи йоп текст, че как не пацан?"
                  }
                ]
              })(<TextArea placeholder="Текст-хуекст" autosize />)}
            </Form.Item>
            <Form.Item>
              <Button
                type="primary"
                htmlType="submit"
                disabled={hasErrors(getFieldsError())}
              >
                СОХРОНИ
              </Button>
            </Form.Item>
          </Form>
        </Drawer>
      </div>
    );
  }
}

export default Form.create({ name: "create_form" })(App);
