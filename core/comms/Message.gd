class_name Message

# from server
const ACCEPT_CREATE_ROOM = "accept_create_room"
const REJECT_CREATE_ROOM = "reject_create_room"
const PLAYER_TO_HOST = "player_to_host"
const HEARTBEAT_PING = "heartbeat_ping"

# to server
const REQUEST_CREATE_ROOM = "create_room"
const HOST_TO_PLAYER = "host_to_player"
const ADD_PLAYER = "add_player"
const UPDATE_PLAYER_INFO = "update_player_info"
const HEARTBEAT_PONG = "heartbeat_pong"

# from player
const REQUEST_JOIN = "request_join"
const REQUEST_REJOIN = "request_rejoin"
const PROMPT_RESPONSE = "prompt_response"

# to player
const ACCEPT_JOIN = "accept_join"
const REJECT_JOIN = "reject_join"
const ACCEPT_REJOIN = "accept_rejoin"
const REJECT_REJOIN = "reject_rejoin"
const REQUEST_INPUT = "request_input"
const REJECT_INPUT = "reject_input"
const HIDE_PROMPT = "hide_prompt"

static func create(type: String, data):
  return {"type": type, "protocolVersion": "", "data": data}