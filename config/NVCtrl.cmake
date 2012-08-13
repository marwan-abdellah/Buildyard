if(MSVC OR APPLE OR LINUX_PPC)
  return()
endif()

set(NVCTRL_VERSION 1.0.0)
set(NVCTRL_REPO_URL https://github.com/marwan-abdellah/NVCtrl)
set(NVCTRL_REPO_TAG master)
set(NVCTRL_NOTEST ON)
set(NVCTRL_OPTIONAL ON)
