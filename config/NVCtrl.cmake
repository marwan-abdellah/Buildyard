# can't autopain on Windows without too much hassle
# can't build universal on OS X
if(MSVC OR APPLE)
  return()
endif()

set(NVCTRL_VERSION 1.0.0)
set(NVCTRL_REPO_URL https://github.com/marwan-abdellah/NVCtrl)
set(HWLOC_REPO_TYPE GIT)
set(NVCTRL_REPO_TAG master)



