function(copy_base_translations target)
  set(BASE_TRANSLATIONS_DIR "${QT_BINARY_DIRECTORY}/../translations")

  if(NOT APPLE)
    add_custom_command(TARGET ${target} POST_BUILD
      COMMAND "${CMAKE_COMMAND}" -E make_directory "$<TARGET_FILE_DIR:${target}>/translations")
  endif()
    
  file(GLOB qmFiles "${BASE_TRANSLATIONS_DIR}/qt_*.qm")
  foreach(path IN LISTS qmFiles)
    get_filename_component(file ${path} NAME)

    # qt_help_<lang> just has to ruin everything.
    if(file MATCHES "qt_help_" OR NOT file MATCHES "qt_([^.]+).qm")
      continue()
    endif()

    # If qtbase_<lang>.qm exists, merge all qms for that language into a single qm.
    set(lang "${CMAKE_MATCH_1}")
    set(baseQmPath "${BASE_TRANSLATIONS_DIR}/qtbase_${lang}.qm")
    if(EXISTS "${baseQmPath}")
      set(outPath "${CMAKE_CURRENT_BINARY_DIR}/qt_${lang}.qm")
      set(srcQmFiles)
      file(GLOB langQmFiles "${BASE_TRANSLATIONS_DIR}/qt*${lang}.qm")
      foreach(qmFile IN LISTS langQmFiles)
        get_filename_component(file ${qmFile} NAME)
        if(file STREQUAL "qt_${lang}.qm")
          continue()
        endif()
        LIST(APPEND srcQmFiles "${qmFile}")
      endforeach()
      add_custom_command(OUTPUT ${outPath}
        COMMAND Qt6::lconvert -verbose -of qm -o "${outPath}" ${srcQmFiles}
        DEPENDS ${srcQmFiles}
      )
      set(path "${outPath}")
    endif()

    target_sources(${target} PRIVATE ${path})
    if(APPLE)
      set_source_files_properties(${path} PROPERTIES MACOSX_PACKAGE_LOCATION Resources/translations)
    elseif(WIN32)
      # TODO: Set the correct binary instead of relying on make install on Windows...
      install(FILES "${path}" DESTINATION "${CMAKE_SOURCE_DIR}/bin/translations")
    else()
      add_custom_command(TARGET ${target} POST_BUILD
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${path}" "$<TARGET_FILE_DIR:${target}>/translations")
    endif()
  endforeach()
endfunction()
