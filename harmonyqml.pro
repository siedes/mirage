# widgets: Make native file dialogs available to QML (must use QApplication)
QT        = quick widgets
DEFINES  += QT_DEPRECATED_WARNINGS
CONFIG   += warn_off c++11 release
TEMPLATE  = app

BUILD_DIR   = build
MOC_DIR     = $$BUILD_DIR/moc
OBJECTS_DIR = $$BUILD_DIR/obj
RCC_DIR     = $$BUILD_DIR/rcc

QRC_FILE = $$BUILD_DIR/resources.qrc

RESOURCES += $$QRC_FILE
HEADERS   += src/utils.h src/clipboard.h \
             submodules/RadialBarDemo/radialbar.h
SOURCES   += src/main.cpp src/utils.cpp src/clipboard.cpp \
             submodules/RadialBarDemo/radialbar.cpp
TARGET     = harmonyqml


# Custom CONFIG options

dev {
    CONFIG    -= warn_off release
    CONFIG    += debug qml_debug declarative_debug
    RESOURCES -= $$QRC_FILE

    warning(make install cannot be used with the dev CONFIG option.)
}


# Files to copy for `make install`

win32:executables.path  = "C:/Program Files"
!win32:executables.path = /usr/local/bin
executables.files       = $$TARGET

!dev:INSTALLS += executables


# Libraries includes

include(submodules/qsyncable/qsyncable.pri)


# Custom functions

defineReplace(glob_filenames) {
    for(pattern, ARGS) {
        results *= $$files(src/$${pattern}, true)
    }
    return($$results)
}


# Generate resource file

RESOURCE_FILES *= $$glob_filenames(qmldir, *.qml, *.qpl, *.js, *.py)
RESOURCE_FILES *= $$glob_filenames( *.jpg, *.jpeg, *.png, *.svg)

file_content += '<!-- vim: set ft=xml : -->'
file_content += '<!DOCTYPE RCC>'
file_content += '<RCC version="1.0">'
file_content += '<qresource prefix="/">'

for(file, RESOURCE_FILES) {
    file_content += '    <file alias="$$file">../$$file</file>'
}

file_content += '</qresource>'
file_content += '</RCC>'

write_file($$QRC_FILE, file_content)


# Add stuff to `make clean`

# Allow cleaning folders instead of just files
win32:QMAKE_DEL_FILE = rmdir /q /s
!win32:QMAKE_DEL_FILE = rm -rf

for(file, $$list($$glob_filenames(*.py))) {
    PYCACHE_DIRS *= $$dirname(file)/__pycache__
    PYCACHE_DIRS *= $$dirname(file)/.mypy_cache
}

QMAKE_CLEAN *= $$MOC_DIR $$OBJECTS_DIR $$RCC_DIR $$PYCACHE_DIRS $$QRC_FILE
QMAKE_CLEAN *= $$BUILD_DIR $$TARGET Makefile .qmake.stash
QMAKE_CLEAN *= $$glob_filenames(*.pyc, *.qmlc, *.jsc, *.egg-info)
