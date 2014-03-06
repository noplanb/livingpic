# ==========================
# = Javascript Convenience =
# ==========================
class window.NPBTimer
  @t = null
  @last = null
  
  @start: => 
    @t = new Date
    @last = @t
    
  @print: (txt) => 
    now = new Date
    Debug.log "#{txt} t-#{now - @t} d-#{now - @last}"
    @last = now
  
  
window.events_for_element = (el) -> $._data($(el).get(0), "events")

window.functions_of_object = (obj) ->
  test = for id, candidate of obj
    try
      "#{id}" if typeof(candidate) is "function"
    catch error
      console.log(error)

# Converts arrays with this structure: [{name1: n1, value1: v1}, {name2: n2, value2: v2}]
# To this structure: {n1: v1, n2:v2}
# Useful for forms serialized into arrays but be careful it will break for form elements with the same name
window.array_to_hash = (arr) ->
  result = {}
  for hsh in arr 
    do ->
      result[hsh.name] = hsh.value
  result

# Converts hashes of the form {key1: value1, key2: value2} 
# To an array of this structure [[key1, value1], [key2, value2]]
window.hash_to_array = (hash) ->
  result = []
  for key in keys(hash)
    do ->
      result.push [key, hash[key.toString()]]
  result


# Takes an array with this structure: [{name1: n1, value1: v1}, {name2: n2, value2: v2}] which is typical of serialized form data
# and it returns an array of the same structure with all values trimmed of leading and trailing whitespace.
window.trim_all_form_data = (fd) ->
  $.map(fd, (hsh) -> {name: hsh.name, value: $.trim(hsh.value)})
  

# Convert nulls to "". Useful converting variables to strings where you want null to just appear as blank.
window.cln_str = (obj) ->
  if obj? then "" + obj else ""
  

window.keys = (hsh) ->
  result=[]
  $.each(hsh, (key) -> result.push(key.toString()))
  result

# ===============
# = CSS helpers =
# ===============
window.set_transition = (elem, params) ->  elem.css(property, params) for property in ["-webkit-transition", "transition"]

# =========
# = Debug =
# =========
class window.Debug
  @log: (r) -> console.log "********** #{r}"
  
  # These two are useful for debugging methods with callbacks in weinre such as cordova plugins.
  @pass: (obj) => 
    Logger.log "pass"
    Debug.result = obj
    
  @fail: (obj) => 
    Logger.log "fail"
    Logger.log obj
    Debug.result = obj 

# ===============
# = URL Helpers =
# ===============
class window.LpUrl
  @is_local: (uri) =>
    return true if new Uri(uri).path().match /assets\/img\/livingpic\/pic1.jpg/ #Special case for the dummy photo capture in the browser.
    new Uri(uri).protocol().match /file|content/
    
  @is_remote: (uri) => !LpUrl.is_local(uri)
    
  @host: (uri) => new Uri(uri).host()
  
  @full_url: (uri) => if new Uri(uri).protocol() != "" then uri else Config.base_url() + if uri.substring(0,1) is "/" then uri else "/" + uri
  
  @url_exists: (url) -> 
    r = $.ajax({
      url: url
      type: 'HEAD'
      async: false
    }).status
    r is "200"
  
# =====================
# = LivingPic Helpers =
# =====================
window.lp_date_format = (date) -> 
  return "" unless date?
  if typeof(date) == "string" then Date.parse(date).toString("MMM d yyyy") else date.toString("MMM d yyyy")

window.m_y_date_format = (date) -> 
  return "" unless date?
  if typeof(date) == "string" then Date.parse(date).toString("MMM yyyy") else date.toString("MMM yyyy")

# Display names helpers
window.first_and_last_initial = (user) -> "#{user.first_name.capitalize_words()} #{initial_letter(user.last_name)}"
window.full_name = (user) -> "#{user.first_name.capitalize_words()} #{if user.last_name then user.last_name.capitalize_words() else ""}"

window.now = -> (new Date).getTime()
window.ms_since = (time) -> now() - time

# ========================
# = Extensions to String =
# ========================
String.prototype.capitalize_words = () -> this.toLowerCase().replace(/^.|\s\S/g, (a) -> a.toUpperCase());

String.prototype.is_email = () ->
  regex = /^([a-zA-Z0-9_\.\-\+])+\@(([a-zA-Z0-9\-])+\.)+([a-zA-Z0-9]{2,4})+$/
  return regex.test(this)

String.prototype.is_phone = () -> this.replace(/[^+\d]/g,"").length >= 10
String.prototype.trim_phone = () -> this.replace(/[^+\d]/g,"")
  
String.prototype.initial = () ->  if this.length > 0 then "#{this[0].toUpperCase()}" else ""
window.initial_letter = (str) -> if typeof str is "string" and str.length > 0 then str[0].toUpperCase() else "" 

String.prototype.briefly = (l) -> if this.length <= l then this.toString() else this[0..l-1] + "&hellip;"

String.prototype.truncate = (l) -> if this.length <= l then this.toString() else this[0..l-1]

String.prototype.escape_html = ->
  chr = {"&": "&amp;", "<": "&lt;", ">": "&gt;", '"': '&quot;', "'": '&#39;', "/": '&#x2F;'}
  String(this).replace(/[&<>"'\/]/g, (s) -> chr[s])

String.prototype.strip_vertical_space = -> String(this).replace(/[\r\n\v\f]+/g, " ")
  
String.prototype.trim = () -> String(this).replace(/^\s+/, "").replace(/\s+$/, "")

String.prototype.is_blank = () -> String(this) is ""

# ==================================
# = Normalizing Android and Iphone =
# ==================================
window.touch_page_x = (e) -> if Config.is_android() then e.touches[0].pageX else e.pageX
window.touch_page_y = (e) -> if Config.is_android() then e.touches[0].pageY else e.pageY

# =======================
# = Extensions to Array =
# =======================
window.is_array = (obj) -> Object.prototype.toString.call(obj) is '[object Array]'

window.to_array = (obj) -> if obj instanceof Array then obj else [obj]

Array.prototype.is_blank = () -> this.length is 0

Array.prototype.minus = (b) -> this.filter (a) -> b.indexOf(a) is -1 
Array.prototype.intersect = (b) -> this.filter (a) -> b.indexOf(a) > -1 
  
# Must be an array of numbers
Array.prototype.max = () -> Math.max.apply( Math, this )
Array.prototype.min = () -> Math.min.apply( Math, this )
Array.prototype.sum = () -> 
  sum = 0
  sum += n for n in this
  sum

Array.prototype.mean = () -> this.sum() / this.length
Array.prototype.average = () -> this.mean()

Array.prototype.last = (n=1) -> 
  return null if this.length is 0 and n is 1
  n = if n > this.length then this.length else n
  if n is 1 then this[this.length - 1] else this[(this.length-n)..(this.length - 1)]
  
Array.prototype.first = (n=1) -> 
  return null if this.length is 0 and n is 1
  return this if n < 0
  if n is 1 then this[0] else this[0..n-1]

Array.prototype.longest_word = () -> this.sort((a,b) -> b.length - a.length)[0]
Array.prototype.shortest_word = () -> this.sort((a,b) -> a.length - b.length)[0]

Array.prototype.includes = (el) -> $.inArray(el, this) isnt -1

# Remvoe one or more elements from the array
Array.prototype.remove = (args...) ->
  output = []
  for arg in args
    index = @indexOf arg
    output.push @splice(index, 1) if index isnt -1
  output = output[0] if args.length is 1
  output

Array.prototype.to_sentence = () ->
  if this.length == 0 
    ""
  else if this.length == 1
    this[0].toString()
  else if this.length == 2
    this[0].toString() + " and " + this[1].toString()
  else
    this[0...this.length-1].join(", ") + ", and " + this[this.length-1]

Array.prototype.uniq = () ->
  h = {}
  for el in this
    do ->
      h[el] = true
  return keys(h)