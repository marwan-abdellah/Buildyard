
find_program(DOT_EXECUTABLE dot)

function(CREATE_DEPENDENCY_GRAPH_R NAME FILE)
  string(TOUPPER ${NAME} UPPER_NAME)

  foreach(_dep ${${UPPER_NAME}_DEPENDS})
    file(APPEND ${FILE} "\"${_dep}\" -> \"${NAME}\";" )
    create_dependency_graph_r(${_dep} ${FILE})
  endforeach()
endfunction()

function(CREATE_DEPENDENCY_GRAPH DIR NAME)
  file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/${NAME}.dot "strict digraph G {" )
  create_dependency_graph_r(${NAME} ${CMAKE_CURRENT_BINARY_DIR}/${NAME}.dot)
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