#if defined _walknode_included
  #endinput
#endif
#define _walknode_included

native walknode_get_origin(index, Float:origin[3]);
native walknode_get_angle(index, Float:angle[3]);
native bool:walknode_get_ducking(index);
native walknode_count();