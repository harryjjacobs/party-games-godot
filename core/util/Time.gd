class_name Time

static func formatted_timestamp():
  var time = OS.get_datetime()
  var day = time["day"]
  var month = time["month"]
  var year = time["year"]
  var hour = time["hour"]
  var minute = time["minute"]
  var second = time["second"]
  return str("%02d" % [day]) + "-" + str("%02d" % [month]) + "-" + str(year) + "_" + str("%02d" % [hour]) + ":" + str("%02d" % [minute]) + ":" + str("%02d" % [second])

