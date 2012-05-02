
find_program(DOT_EXECUTABLE dot)

function(CREATE_DEPENDENCY_GRAPH_R NAME ALL FILE)
  string(TOUPPER ${NAME} UPPER_NAME)

  foreach(_dep ${${UPPER_NAME}_DEPENDS})
    file(APPEND ${FILE} "\"${_dep}\" -> \"${NAME}\";" )
    file(APPEND ${CMAKE_CURRENT_BINARY_DIR}/${ALL}.dot
      "\"${_dep}\" -> \"${NAME}\";" )
    create_dependency_graph_r(${_dep} ${ALL} ${FILE})
  endforeach()
endfunction()

function(CREATE_DEPENDENCY_GRAPH_START DIR)
  get_filename_component(dir ${DIR} NAME)
  file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/${dir}.dot "strict digraph G {" )
endfunction()

function(CREATE_DEPENDENCY_GRAPH DIR NAME)
  get_filename_component(dir ${DIR} NAME)
  file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/${NAME}.dot "strict digraph G {" )

  create_dependency_graph_r(${NAME} ${dir}
    ${CMAKE_CURRENT_BINARY_DIR}/${NAME}.dot)
  file(APPEND ${CMAKE_CURRENT_BINARY_DIR}/${NAME}.dot "}" )
  if(NOT DOT_EXECUTABLE MATCHES "DOT_EXECUTABLE-NOTFOUND")
    add_custom_command(OUTPUT ${DIR}/${NAME}.png
      COMMAND ${DOT_EXECUTABLE} -o ${DIR}/${NAME}.png -Tpng
        ${CMAKE_CURRENT_BINARY_DIR}/${NAME}.dot
      DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/${NAME}.dot
     )
    add_custom_target(${NAME}-png ALL DEPENDS ${DIR}/${NAME}.png)
 endif()
endfunction()

function(CREATE_DEPENDENCY_GRAPH_END DIR)
  get_filename_component(dir ${DIR} NAME)
  file(APPEND ${CMAKE_CURRENT_BINARY_DIR}/${dir}.dot "}" )
  if(NOT DOT_EXECUTABLE MATCHES "DOT_EXECUTABLE-NOTFOUND")
    add_custom_command(OUTPUT ${DIR}/all.png
      COMMAND ${DOT_EXECUTABLE} -o ${DIR}/all.png -Tpng
      ${CMAKE_CURRENT_BINARY_DIR}/${dir}.dot
      DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/${dir}.dot
      )
    add_custom_target(${dir}_png ALL DEPENDS ${DIR}/all.png)
  endif()
endfunction() 