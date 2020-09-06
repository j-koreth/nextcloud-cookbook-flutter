import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:nextcloud_cookbook_flutter/src/services/user_repository.dart';

import '../../blocs/login/login.dart';

class LoginForm extends StatefulWidget {
  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> with WidgetsBindingObserver {
  final _serverUrl = TextEditingController();
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a `GlobalKey<FormState>`,
  // not a GlobalKey<MyCustomFormState>.
  final _formKey = GlobalKey<FormState>();

  Function authenticateInterruptCallback;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      authenticateInterruptCallback();
      debugPrint("WAT");
    }
  }

  @override
  initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    authenticateInterruptCallback = () {
      UserRepository().stopAuthenticate();
    };

    _onLoginButtonPressed() {
      if (_formKey.currentState.validate()) {
        BlocProvider.of<LoginBloc>(context).add(
          LoginButtonPressed(
            serverURL: _serverUrl.text.trim(),
          ),
        );
      }
    }

    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state is LoginFailure) {
          Scaffold.of(context).showSnackBar(
            SnackBar(
              content: Text('${state.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: BlocBuilder<LoginBloc, LoginState>(
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Form(
              // Build a Form widget using the _formKey created above.
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Server URL'),
                    controller: _serverUrl,
                    keyboardType: TextInputType.url,
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'Please enter a Nextcloud URL';
                      }
                      var urlPattern =
                          r"([-A-Z0-9.]+)(/[-A-Z0-9+&@#/%=~_|!:,.;]*)?(\?[A-Z0-9+&@#/%=~_|!:‌​,.;]*)?";
                      bool _match = new RegExp(urlPattern, caseSensitive: false)
                          .hasMatch(value);
                      if (!_match) {
                        return 'Please enter a valid URL';
                      }
                      return null;
                    },
                    onFieldSubmitted: (val) {
                      if (state is! LoginLoading) {
                        _onLoginButtonPressed();
                      }
                    },
                    textInputAction: TextInputAction.done,
                  ),
                  RaisedButton(
                    onPressed:
                        state is! LoginLoading ? _onLoginButtonPressed : null,
                    child: Text('Login'),
                  ),
                  Container(
                    child: state is LoginLoading
                        ? SpinKitWave(color: Colors.blue, size: 50.0)
                        : null,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
