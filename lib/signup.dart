import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:email_validator/email_validator.dart';

class SignupPage extends StatefulWidget {
  static String tag = 'signup-page';
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isAdmin = false;
  bool _isLoading = false;
  String? _errorMessage;

  void _handleSignUp() async {



    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final auth = FirebaseAuth.instance;
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final confirmPassword = _confirmPasswordController.text.trim();
      final username = _usernameController.text.trim();

      if (!EmailValidator.validate(email)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid email')),
        );
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      if (password != confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match')),
        );
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final UserCredential userCredential =
          await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({'email': email, 'username': username, 'statusAdmin': _isAdmin});

      Navigator.pop(context, userCredential.user);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('The password provided is too weak')),
        );
      } else if (e.code == 'email-already-in-use') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('The account already exists for that email')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred, try again')),
        );
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred, try again')),
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
Widget build(BuildContext context) {
  
  final email = TextFormField(
    controller: _emailController,
    keyboardType: TextInputType.emailAddress,
    decoration: InputDecoration(
      hintText: 'Email',
      contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(32.0)),
    ),
    validator: (value) {
      if (value!.isEmpty) {
        return 'Please enter your email';
      }
      return null;
    },
  );

  final username = TextFormField(
    controller: _usernameController,
    decoration: InputDecoration(
      hintText: 'Username',
      contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(32.0)),
    ),
    validator: (value) {
      if (value!.isEmpty) {
        return 'Please enter your username';
      }
      return null;
    },
  );

  final password = TextFormField(
    controller: _passwordController,
    obscureText: true,
    decoration: InputDecoration(
      hintText: 'Password',
      contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(32.0)),
    ),
    validator: (value) {
      if (value!.isEmpty) {
        return 'Please enter your password';
      }
      return null;
    },
  );

  final confirmPassword = TextFormField(
    controller: _confirmPasswordController,
    obscureText: true,
    decoration: InputDecoration(
      hintText: 'Confirm Password',
      contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(32.0)),
    ),
    validator: (value) {
      if (value != _passwordController.text) {
        return 'Passwords do not match';
      }
      return null;
    },
  );

  final checkAdminStatus = CheckboxListTile(
    title: Text('Are you an Admin?'),
    value: _isAdmin,
    onChanged: (newValue) {
      setState(() {
        _isAdmin = newValue!;
      });
    },
  );

  final signUpButton = ElevatedButton(
    onPressed: _isLoading ? null : _handleSignUp,
    child: _isLoading ? CircularProgressIndicator() : Text('Sign Up'),
    style: ButtonStyle(
      padding: MaterialStateProperty.all(EdgeInsets.all(12)),
      backgroundColor: MaterialStateProperty.all(Colors.lightBlueAccent),
      shape: MaterialStateProperty.all(RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      )),
    ),
  );

  final loginLink = TextButton(
    onPressed: () {
      Navigator.pop(context);
    },
    child: Text('Already have an account? Login'),
  );

  return Scaffold(
    body: Center(
      child: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.only(left: 24.0, right: 24.0),
        children: <Widget>[
          SizedBox(height: 48.0),
          email,
          SizedBox(height: 8.0),
          username,
          SizedBox(height: 8.0),
          password,
          SizedBox(height: 8.0),
          confirmPassword,
          SizedBox(height: 8.0),
          checkAdminStatus,
          SizedBox(height: 24.0),
          signUpButton,
          loginLink
        ],
      ),
    ),
  );
  }
}