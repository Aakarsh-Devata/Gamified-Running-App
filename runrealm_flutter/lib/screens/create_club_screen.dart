import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/social.dart';
import '../services/club_service.dart';
import '../services/user_service.dart';
import '../providers/auth_provider.dart';

class CreateClubScreen extends StatefulWidget {
  @override
  _CreateClubScreenState createState() => _CreateClubScreenState();
}

class _CreateClubScreenState extends State<CreateClubScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _descController = TextEditingController();
  bool _isCreating = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final uid = authProvider.user?.uid;

    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: Not logged in')));
      setState(() => _isCreating = false);
      return;
    }

    final club = Club(
      name: _nameController.text.trim(),
      city: _cityController.text.trim(),
      description: _descController.text.trim(),
      organizerUid: uid,
      createdAt: Timestamp.now(),
      memberCount: 1,
      tags: [],
    );

    try {
      final clubId = await ClubService.createClub(club);
      await UserService.addClubToProfile(uid, clubId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Club created and joined successfully!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error creating club: $e')));
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Club')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Club Name', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'Please enter a name' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(labelText: 'City', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'Please enter a city' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                maxLines: 3,
                validator: (v) => v == null || v.isEmpty ? 'Please enter a description' : null,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isCreating ? null : _submit,
                child: _isCreating 
                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text('Create Club'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
