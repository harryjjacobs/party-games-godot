extends "res://core/game_stages/RoundBeginStage.gd"

func enter(params):
  .enter(params)
  params.current_round = params.round_generator.next(MemeContest.ContestType.BASIC)
  emit_signal("request_exit", params)