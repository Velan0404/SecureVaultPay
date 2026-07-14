package com.securevaultpay.secure_vault_pay

import io.flutter.embedding.android.FlutterFragmentActivity

// local_auth requires a FragmentActivity host to attach its BiometricPrompt
// fragment; a plain FlutterActivity makes every authenticate() call fail with
// LocalAuthExceptionCode.uiUnavailable ("must be a FragmentActivity").
class MainActivity : FlutterFragmentActivity()
