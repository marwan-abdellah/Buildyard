find_package(DNSSD QUIET)
if(NOT DNSSD_FOUND) # keep servus & gpu-sd optional
  return()
endif()

set(SERVUS_VERSION 0.9)
set(SERVUS_REPO_URL https://github.com/Eyescale/servus.git)
set(SERVUS_REPO_TAG master)
set(SERVUS_DEPENDS Lunchbox Boost)
