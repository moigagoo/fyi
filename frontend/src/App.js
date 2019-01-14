import React, { Component } from "react";
import axios from "axios";
import "./App.css";
import { Table, Input, Button, Popconfirm, Form, notification } from "antd";

const FormItem = Form.Item;
const EditableContext = React.createContext();
const { TextArea } = Input;

const EditableRow = ({ form, index, ...props }) => (
  <EditableContext.Provider value={form}>
    <tr {...props} />
  </EditableContext.Provider>
);

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
                    />
                  )}
                </FormItem>
              ) : (
                <pre
                  className="editable-cell-value-wrap"
                  style={{ paddingRight: 24 }}
                  onClick={this.toggleEdit}
                >
                  {restProps.children}
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
      dataSource: []
    };
  }

  componentDidMount() {
    axios.get("/api/entries").then(response => {
      this.setState({ dataSource: response.data });
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
    const index = newData.findIndex(item => row.key === item.key);
    const item = newData[index];
    newData.splice(index, 1, {
      ...item,
      ...row
    });
    this.setState({ dataSource: newData });
  };

  handleSearch = e => {
    this.setState({ search: e.target.value });
  };

  render() {
    const { dataSource, search } = this.state;
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
          dataSource={filteredDataSource}
          columns={columns}
        />
      </div>
    );
  }
}

export default App;
