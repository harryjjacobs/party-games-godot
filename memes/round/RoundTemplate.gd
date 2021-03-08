extends Node

export(NodePath) var round_begin_stage
export(NodePath) var prompt_requests_stage
export(NodePath) var player_response_contest_stage
export(NodePath) var round_end_stage

func build_stages():
  return [
    get_node(round_begin_stage),
    get_node(prompt_requests_stage),
    get_node(player_response_contest_stage),
    get_node(round_end_stage),
  ]