// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

@immutable
class Person {
  final String name;
  final int age;
  final String uuid;

  Person({
    required this.name,
    required this.age,
    String? uuid,
  }) : uuid = uuid ?? const Uuid().v4();

  Person copyWith({
    String? name,
    int? age,
  }) {
    return Person(
      name: name ?? this.name,
      age: age ?? this.age,
      uuid: uuid,
    );
  }

  String get displayName => '$name ($age years old)';
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'age': age,
      'uuid': uuid,
    };
  }

  factory Person.fromMap(Map<String, dynamic> map) {
    return Person(
      name: map['name'] as String,
      age: map['age'] as int,
      uuid: map['uuid'] as String,
    );
  }
  @override
  String toString() => 'Person(name: $name, age: $age, uuid: $uuid)';

  @override
  bool operator ==(covariant Person other) {
    if (identical(this, other)) return true;

    return other.uuid == uuid;
  }

  @override
  int get hashCode => name.hashCode ^ age.hashCode ^ uuid.hashCode;
}

class DataModel extends ChangeNotifier {
  final List<Person> _people = [];
  int get count => _people.length;
  UnmodifiableListView<Person> get people => UnmodifiableListView(_people);
  void add(Person person) {
    _people.add(person);
    notifyListeners();
  }

  void remove(Person person) {
    _people.remove(person);
    notifyListeners();
  }

  void update(Person updatedPerson) {
    final index = _people.indexOf(updatedPerson);
    final oldperson = _people[index];
    if (oldperson.name != updatedPerson.name ||
        oldperson.age != updatedPerson.age) {
      _people[index] = oldperson.copyWith(
        name: updatedPerson.name,
        age: updatedPerson.age,
      );
      notifyListeners();
    }
  }
}

final peopleProvider = ChangeNotifierProvider((ref) => DataModel());

class MyHomePage extends ConsumerWidget {
  const MyHomePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final dataModel = ref.watch(peopleProvider);
          return ListView.builder(
            itemCount: dataModel.count,
            itemBuilder: (context, index) {
              final person = dataModel._people[index];
              return ListTile(
                  title: Text(person.displayName),
                  onTap: () async {
                    final updatedPerson = await createOrUpdatePerson(
                      context,
                      existingPerson: person,
                    );
                    if (updatedPerson != null) dataModel.update(updatedPerson);
                  });
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final perso = await createOrUpdatePerson(context);
          print(perso);
          if (perso != null) {
            ref.read(peopleProvider).add(perso);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

final nameController = TextEditingController();
final ageController = TextEditingController();

Future<Person?> createOrUpdatePerson(BuildContext context,
    {Person? existingPerson}) {
  String? name = existingPerson?.name;
  int? age = existingPerson?.age;
  nameController.text = name ?? '';
  ageController.text = age?.toString() ?? '';
  return showDialog<Person?>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Create or update person'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: 'Name'),
          onChanged: (value) => name = value,
        ),
        TextField(
          controller: ageController,
          decoration: const InputDecoration(hintText: 'Age'),
          onChanged: (value) => age = int.tryParse(value),
        ),
      ]),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        TextButton(
            onPressed: () {
              if (age != null && name != null) {
                if (existingPerson != null) {
                  final newPerson = existingPerson.copyWith(
                    name: name,
                    age: age,
                  );
                  Navigator.pop(context, newPerson);
                } else {
                  Navigator.pop(context, Person(name: name!, age: age!));
                }
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('Save'))
      ],
    ),
  );
}
