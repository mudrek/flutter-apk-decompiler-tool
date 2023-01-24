class States {}

class InitialState extends States {}

class LoadingState extends States {}

class ErrorState extends States {
  final String message;

  ErrorState(this.message);
}

class Step1State extends States {
  final bool success;
  final bool loading;

  Step1State(this.success, this.loading);
}

class Step2State extends States {
  final bool success;
  final bool loading;

  Step2State(this.success, this.loading);
}

class Step3State extends States {
  final bool success;
  final bool loading;

  Step3State(this.success, this.loading);
}
