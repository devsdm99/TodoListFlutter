import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(TodoApp());

class Todo {
  String what;
  bool done;
  Todo(this.what) : done = false;

  void toggleDone() => done = !done;
  Todo.fromJson(Map<String, dynamic> json)
      : what = json['what'],
        done = json['done'];

  Map<String, dynamic> toJson() => {'what': what, 'done': done};
}

class TodoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: new TodoListPage(),
    );
  }
}

class TodoListPage extends StatefulWidget {
  const TodoListPage({
    Key key,
  }) : super(key: key);

  @override
  _TodoListPageState createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  List<Todo> _todos;

  int get _doneCount => _todos.where((todo) => todo.done).length;

  @override
  void initState() {
    _readTodos();
    super.initState();
  }

  _readTodos() async {
    try{
    Directory dir = await getApplicationDocumentsDirectory();
    File file = File('${dir.path}/todos.json');
    List json = jsonDecode(await file.readAsString());

    List<Todo> todos = [];
    for(var item in json){
      todos.add(Todo.fromJson(item));
    }
    super.setState(() =>_todos = todos);
    }catch(e){
      setState(() {
        _todos =  [];
      });
    }
  }

  void setState(fn) {
    super.setState(fn);
    _writeTodos();
  }

  _writeTodos() async {
    try {
      Directory dir = await getApplicationDocumentsDirectory();
      File file = File('${dir.path}/todos.json');

      String jsonText = jsonEncode(_todos);
      print(jsonText);
      await file.writeAsString(jsonText);
    } catch (e) {
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text("No he podido grabar el fichero"),
      ));
    }
  }

  _buildList() {
    if (_todos == null) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
    return ListView.builder(
      itemCount: _todos.length,
      itemBuilder: (context, index) => InkWell(
        onTap: () {
          setState(() {
            _todos[index].toggleDone();
          });
        },
        child: ListTile(
          title: Text(
            _todos[index].what,
            style: TextStyle(
              decoration: (_todos[index].done
                  ? TextDecoration.lineThrough
                  : TextDecoration.none),
            ),
          ),
          leading: Checkbox(
            value: _todos[index].done,
            onChanged: (checked) {
              setState(() {
                _todos[index].done = checked;
              });
            },
          ),
        ),
      ),
    );
  }

  _removeChecked() {
    List<Todo> pending = [];

    for (var todo in _todos) {
      if (!todo.done) pending.add(todo);
    }

    setState(() {
      _todos = pending;
    });
  }

  @override
  Widget build(BuildContext context) {
    _askRemoveChecked() {
      if (_doneCount == 0) {
        return;
      }
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("COnfirmacion"),
          content: Text("Seguro que quieres borrar los marcados?"),
          actions: <Widget>[
            FlatButton(
              child: Text("Si"),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
            FlatButton(
              child: Text("Cancelar"),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            )
          ],
        ),
      ).then((borrar) {
        if (borrar) {
          _removeChecked();
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("TodoApp"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _askRemoveChecked,
          ),
        ],
      ),
      body: _buildList(),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.of(context)
              .push(
            MaterialPageRoute(
              builder: (_) => NewTodoPage(),
            ),
          )
              .then((what) {
            setState(() {
              _todos.add(Todo(what));
            });
          });
        },
      ),
    );
  }
}

class NewTodoPage extends StatefulWidget {
  @override
  _NewTodoPageState createState() => _NewTodoPageState();
}

class _NewTodoPageState extends State<NewTodoPage> {
  TextEditingController _controller;

  @override
  void initState() {
    _controller = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add new Todo.."),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _controller,
              onSubmitted: (what) {
                Navigator.of(context).pop(what);
              },
            ),
            RaisedButton(
              child: Text("Añadir a lista"),
              onPressed: () {
                Navigator.of(context).pop(_controller.text);
              },
            )
          ],
        ),
      ),
    );
  }
}
