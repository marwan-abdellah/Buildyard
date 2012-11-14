
# Copyright (c) 2012 Stefan Eilemann <Stefan.Eilemann@epfl.ch>

# WAR for bug fixed in 2.8.9: http://public.kitware.com/Bug/view.php?id=12564
# overwrite git clone script generation to avoid excessive cloning
function(_ep_write_gitclone_script script_filename source_dir git_EXECUTABLE git_repository git_tag name work_dir)

  string(TOUPPER ${name} NAME)
  set(TAIL_REVISION ${${NAME}_TAIL_REVISION})
  if(TAIL_REVISION)
      set(TAIL_REVISION_CMD "-r"${TAIL_REVISION})
  endif(TAIL_REVISION)

  file(WRITE ${script_filename}
"if(\"${git_tag}\" STREQUAL \"\")
  message(FATAL_ERROR \"Tag for git checkout should not be empty.\")
endif()
if(IS_DIRECTORY \"${work_dir}/${name}/.git\")
  execute_process(
    COMMAND \"${git_EXECUTABLE}\" fetch
    WORKING_DIRECTORY \"${work_dir}/${name}\"
    )
  execute_process(
    COMMAND \"${git_EXECUTABLE}\" checkout ${git_tag}
    WORKING_DIRECTORY \"${work_dir}/${name}\"
    RESULT_VARIABLE error_code
    )
  if(error_code)
    message(WARNING \"Failed to checkout ${git_tag} in '${source_dir}'\")
  endif()
else()
  execute_process(
    COMMAND \${CMAKE_COMMAND} -E remove_directory \"${source_dir}\"
    RESULT_VARIABLE error_code
    )
  if(error_code)
    message(FATAL_ERROR \"Failed to remove directory: '${source_dir}'\")
  endif()
  execute_process(
    COMMAND \"${git_EXECUTABLE}\" ${GIT_SVN} clone ${TAIL_REVISION_CMD} \"${git_repository}\" \"${name}\"
    WORKING_DIRECTORY \"${work_dir}\"
    RESULT_VARIABLE error_code
    )
  if(error_code)
    message(FATAL_ERROR \"Failed to clone repository: '${git_repository}'\")
  endif()

  execute_process(
    COMMAND \"${git_EXECUTABLE}\" checkout ${git_tag}
    WORKING_DIRECTORY \"${work_dir}/${name}\"
    RESULT_VARIABLE error_code
    )
  if(error_code)
    message(FATAL_ERROR \"Failed to checkout tag: '${git_tag}'\")
  endif()
endif()

execute_process(
  COMMAND \"${git_EXECUTABLE}\" submodule init
  WORKING_DIRECTORY \"${work_dir}/${name}\"
  RESULT_VARIABLE error_code
  )
if(error_code)
  message(FATAL_ERROR \"Failed to init submodules in: '${work_dir}/${name}'\")
endif()

execute_process(
  COMMAND \"${git_EXECUTABLE}\" submodule update --recursive
  WORKING_DIRECTORY \"${work_dir}/${name}\"
  RESULT_VARIABLE error_code
  )
if(error_code)
  message(FATAL_ERROR \"Failed to update submodules in: '${work_dir}/${name}'\")
endif()

"
)
endfunction(_ep_write_gitclone_script)
