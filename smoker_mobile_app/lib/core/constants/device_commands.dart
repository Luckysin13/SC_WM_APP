class DeviceCommands {
  static const String getValues = 'getValues';
  static const String getHistory = 'getHistory';
  static const String getOtaInfo = 'getOTAInfo';
  static const String checkOtaUpdates = 'checkOTAUpdates';
  static const String startOtaUpdate = 'startOTAUpdate';
  
  static const String fanModeAuto = 'FanMode:auto';
  static const String fanModeOff = 'FanMode:off';
  
  static String setSetpoint(int setpoint) => '2b$setpoint';
  static String setMeatDoneSetpoint(int setpoint) => '8b$setpoint';
  static String setKeepWarmSetpoint(int setpoint) => '9b$setpoint';
  
  static String setKeepWarm(bool enabled) => 'KeepWarm$enabled';
  static String setDoneAlarm(bool enabled) => 'DoneAlarm$enabled';
  
  static String calibratePit(int offset) => 'CalibratePit:$offset';
  static String calibrateMeat(int offset) => 'CalibrateMeat:$offset';
  
  static String updatePid(double kp, double ki, double kd) => 'UpdatePID:$kp:$ki:$kd';
  static String updateTimezone(int offsetSeconds) => 'UpdateTimezone:$offsetSeconds';
  
  static String setAutotune(bool enabled) => 'StartAutotune:$enabled';
}
