extends Control

var json = {}
var weather = {}

var airport_icao = "EFRO"
var airport_city = "Rovaniemi"

#Vatsim Statistics.
var connected_clients = 0
var rovaniemi_arrivals = 0
var rovaniemi_departures = 0

#Amount of pilots.
var pilot_amount = 0

#Info panel rotation
var info_panel_rotate = false

var metar_response
var weather_response

#Time Variables
var timenow_utc
var timenow
var second
var hour_utc
var hour
var minute
var weekday
var daynr
var month
var update_timer
var metar_timer
var data_update_timer

#random
var from
var arr
var dep

#Local weather.
var temperature_celsius = 0
var temperature_fahrenheit = 0

#Http_request for metar.
onready var metar_grabber = HTTPRequest.new()
#Http_request for local weather data.
onready var weather_grabber = HTTPRequest.new()
#Http_request for Vatsim data.
onready var data_grabber = HTTPRequest.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	#Call the timer, that updates the time for us.
	start_clock_update_timer()
	#Connect METAR Http-request completed signal.
	metar_grabber.connect("request_completed",self,"_on_metar_request_completed")
	#Add metar grabber as child.
	add_child(metar_grabber)
	#Do initial metar pull on launch.
	pull_metar()
	#Also start metar update timer.
	start_metar_update_timer()
	#Call Airport info handler function.
	draw_current_airport()
	#Do initial call to rotate info panel.
	rotate_info_panel()
	
	
	
	
	#Connect Vatsim data Http_request completed signal.
	data_grabber.connect("request_completed",self,"on_vatsim_data_req_completed")
	#Add data grabber as child.
	add_child(data_grabber)
	
	#Do initial pull, of Vatsim Data.
	pull_vatsim_data()
	#Start Vatsim data grabber timer.
	start_vatsim_data_update_timer()
	
	#Connect local weather grabber Http_request completed signal.
	weather_grabber.connect("request_completed",self,"weather_data_req_completed")
	#Add weather grabber as child.
	add_child(weather_grabber)
	
	#Do initial weather pull
	pull_weather()
	#Do init call to rotate temperature panel.
	draw_temperature()
	start_local_weather_timer()


func weather_data_req_completed(result, response_code, headers, body):
	weather = JSON.parse(body.get_string_from_utf8())
	#var grab_temperature_celsius = weather.result.values()
	#var test = weather.result.has("current")
	var grab_details = weather.result.get("current")
	#var test1 = grab_details.has("temp_c")
	var grab_temperature_celsius = grab_details.get("temp_c")
	var grab_temperature_fahrenheit = grab_details.get("temp_f")
	
	temperature_celsius = grab_temperature_celsius
	temperature_fahrenheit = grab_temperature_fahrenheit
	
	print("Temperature set")
	#print("Temp_C"," " ,grab_temperature_celsius)
	#print("Temp_F"," " ,grab_temperature_fahrenheit)

func _on_metar_request_completed(result, response_code, headers, body):
	metar_response = (body.get_string_from_utf8())

func draw_temperature():
	get_node("Header_Panel/HBoxContainer/Temperature_Panel/Temperature_Label").bbcode_text = "[center]" + str(temperature_celsius) + "°C" + "[/center]"
	yield(get_tree().create_timer(5.0), "timeout")
	get_node("Header_Panel/HBoxContainer/Temperature_Panel/Temperature_Label").bbcode_text = "[center]" + str(temperature_fahrenheit) + "°F" + "[/center]"
	yield(get_tree().create_timer(5.0), "timeout")
	draw_temperature()


func rotate_info_panel():
	#Show METAR.
	get_node("Info_Panel/Info_Label").text ="METAR"+" "+str(metar_response)
	#Delay 8. For METAR.
	yield(get_tree().create_timer(8.0), "timeout")
	#Show Network Connection Statistics.
	get_node("Info_Panel/Info_Label").text ="CURRENT CONNECTIONS TO NETWORK:"+" "+str(connected_clients)
	#Delay 5.
	yield(get_tree().create_timer(5.0), "timeout")
	#Show Pilot Connection Statistics.
	get_node("Info_Panel/Info_Label").text ="CURRENT PILOTS CONNECTED:"+" "+str(pilot_amount)
	#Delay 5.
	yield(get_tree().create_timer(5.0), "timeout")
	get_node("Info_Panel/Info_Label").text = "Fly And See Santa 2021  By: VATSIM-SCANDINAVIA"
	#Delay 5.
	yield(get_tree().create_timer(5.0), "timeout")
	get_node("Info_Panel/Info_Label").text ="SIMULATOR: X-PLANE 11.55"
	yield(get_tree().create_timer(5.0), "timeout")
	#Always show sponsor last.
	get_node("Info_Panel/Info_Label").text ="STREAM SPONSORED BY: Erämark-Media"
	#Delay 5.
	yield(get_tree().create_timer(3.0), "timeout")
	
	rotate_info_panel()

func start_metar_update_timer():
	metar_timer = Timer.new()
	metar_timer.connect("timeout",self,"pull_metar")
	add_child(metar_timer)
	metar_timer.start(120)

func start_clock_update_timer():
	update_timer = Timer.new()
	update_timer.connect("timeout",self,"_Update_Clock")
	add_child(update_timer)
	update_timer.start(1)

func start_vatsim_data_update_timer():
	data_update_timer = Timer.new()
	data_update_timer.connect("timeout",self,"pull_vatsim_data")
	add_child(data_update_timer)
	data_update_timer.start(60)

func start_local_weather_timer():
	var weather_timer = Timer.new()
	weather_timer.connect("timeout",self,"pull_weather")
	add_child(weather_timer)
	weather_timer.start(120)

func pull_weather():
	weather_grabber.request("http://api.weatherapi.com/v1/current.json?key=d654d7150a914da7b53122235211012&q=Rovaniemi&aqi=no")

func pull_metar():
	metar_grabber.request("http://metar.vatsim.net/metar.php?id="+airport_icao)

func draw_current_airport():
	#Set current Airport ICAO code.
	get_node("Header_Panel/HBoxContainer/Airport_Panel/Airport_Label").bbcode_text = "[center]"+airport_icao+"[/center]"
	yield(get_tree().create_timer(5.0), "timeout")
	get_node("Header_Panel/HBoxContainer/Airport_Panel/Airport_Label").bbcode_text = "[center]"+airport_city+"[/center]"
	yield(get_tree().create_timer(5.0), "timeout")
	draw_current_airport()

func pull_vatsim_data():
	data_grabber.request("https://data.vatsim.net/v3/vatsim-data.json")

func on_vatsim_data_req_completed(result, response_code, headers, body):
	#var response = (body.get_string_from_utf8())
	#json = JSON.parse(body.get_string_from_utf8())
	
	
	json = JSON.parse(body.get_string_from_utf8())
	
	#var data = json.result
	#print(data)
	
	var grab_general = json.result.get("general",null)
	grab_general = grab_general.get("connected_clients")
	connected_clients = grab_general
	
	#print (connected_clients)
	
	var grab_pilot = json.result.get("pilots",null)
	pilot_amount = grab_pilot.size()
	
	#print("Pilots", pilot_amount)
	
	var grab_plan = json.result.get("pilots",null)
	
	
	#re-set amount of arrivals.
	rovaniemi_arrivals = 0
	#re-set amount of departures.
	rovaniemi_departures = 0
	for i in range(grab_plan.size()):

		#print(i)
		var details = grab_plan[i]
		if not details:
			continue
		
		#Note to self, flight plan can be null!!!!!
		if details.has("flight_plan") and details.flight_plan:
				var plan = details.get("flight_plan")
				if plan.has("arrival"):
				
				
					
					arr = plan.get("arrival")
					
					if arr == "EFRO":
						var rovaniemi = +1
						rovaniemi_arrivals = rovaniemi_arrivals + 1
						
					
					dep = plan.get("departure")
					if dep == "EFRO":
						rovaniemi_departures = rovaniemi_departures +1
	
	#print("Rovaniemi Arrivals", rovaniemi_arrivals)
	get_node("Header_Panel/HBoxContainer/Arrivals_Panel/Arrivals_Label").bbcode_text = "[center]"+str(rovaniemi_arrivals)+"[/center]"
	
	get_node("Header_Panel/HBoxContainer/Departures_Panel/Departures_Label").bbcode_text = "[center]"+str(rovaniemi_departures)+"[/center]"
	#print("Departures", rovaniemi_departures)
	
	
	#var file = File.new()
	#file.open("res://Assets/Debug/data.json", File.WRITE)
	#file.store_string(str(hopp))
	#file.close()


#Time update function.
func _Update_Clock():
	timenow_utc = OS.get_datetime(true)
	timenow = OS.get_datetime()
	hour_utc = timenow_utc["hour"]
	hour = timenow["hour"]
	#Correct Single Digit Hour
	if hour == 1:
		hour = "01"
	elif hour == 2:
		hour = "02"
	elif hour == 3:
		hour = "03"
	elif hour == 4:
		hour = "04"
	elif hour == 5:
		hour = "05"
	elif hour == 6:
		hour = "06"
	elif hour == 7:
		hour = "07"
	elif hour == 8:
		hour = "08"
	elif hour == 9:
		hour = "09"
	elif hour == 0:
		hour = "00"
	
	minute = timenow["minute"]
	#Correct Single Digits For Minutes.
	if minute == 1:
		minute = "01"
	elif minute == 2:
		minute = "02"
	elif minute == 3:
		minute = "03"
	elif minute == 4:
		minute = "04"
	elif minute == 5:
		minute = "05"
	elif minute == 6:
		minute = "06"
	elif minute == 7:
		minute = "07"
	elif minute == 8:
		minute = "08"
	elif minute == 9:
		minute = "09"
	elif minute == 0:
		minute = "00"
	
	second = timenow["second"]
	#correct Single Digits For Seconds.
	if second == 1:
		second = "01"
	elif second == 2:
		second = "02"
	elif second == 3:
		second = "03"
	elif second == 4:
		second = "04"
	elif second == 5:
		second = "05"
	elif second == 6:
		second = "06"
	elif second == 7:
		second = "07"
	elif second == 8:
		second = "08"
	elif second == 9:
		second = "09"
	elif second == 0:
		second = "00"
	
	
	#Convert To Text Representation
	weekday = timenow["weekday"]
	if weekday == 0:
		weekday = "Sun"
	elif weekday == 1:
		weekday = "Mon"
	elif weekday == 2:
		weekday = "Tue"
	elif weekday == 3:
		weekday = "Wed"
	elif weekday == 4:
		weekday = "Thu"
	elif weekday == 5:
		weekday = "Fri"
	else:weekday = "Sat"
	
	
	daynr = timenow["day"]
	if daynr == 1:
		daynr = "01"
	elif daynr == 2:
		daynr = "02"
	elif daynr == 3:
		daynr = "03"
	elif daynr == 4:
		daynr = "04"
	elif daynr == 5:
		daynr = "05"
	elif daynr == 6:
		daynr = "06"
	elif daynr == 7:
		daynr = "07"
	elif daynr == 8:
		daynr = "08"
	elif daynr == 9:
		daynr = "09"
	
	
	month = timenow["month"]
	if month == 1:
		month = "Jan"
	elif month == 2:
		month = "Feb"
	elif month == 3:
		month = "Mar"
	elif month == 4:
		month = "Apr"
	elif month == 5:
		month = "May"
	elif month == 6:
		month = "Jun"
	elif month == 7:
		month = "Jul"
	elif month == 8:
		month = "Aug"
	elif month == 9:
		month = "Sep"
	elif month == 10:
		month = "Oct"
	elif month == 11:
		month = "Nov"
	elif month == 12:
		month = "Dec"
	
	#Set UTC Time.
	get_node("Header_Panel/HBoxContainer/Time_UTC_Panel/Time_Label").bbcode_text = "[center]"+str(hour_utc,":",minute,":",second)+"[/center]"
	#Set Local Time.
	get_node("Header_Panel/HBoxContainer/Time_Local_Panel/Time_Local_Label").bbcode_text = "[center]"+str(hour,":",minute,":",second)+"[/center]"
	#Set Date.
	get_node("Header_Panel/HBoxContainer/Date_Panel/Date_Label").bbcode_text = "[center]"+str(weekday," ",daynr," ",month)+"[/center]"

