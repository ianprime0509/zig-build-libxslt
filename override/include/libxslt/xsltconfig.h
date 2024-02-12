// This file contains only the necessary parts of xsltconfig.h which are not
// configured in the build script.

#ifndef __XML_XSLTCONFIG_H__
#define __XML_XSLTCONFIG_H__

#ifdef WITH_MODULES
#define LIBXSLT_DEFAULT_PLUGINS_PATH() "/usr/local/lib/libxslt-plugins"
#endif

// TODO: zig-build-libxml2 handles this incorrectly, so we have to duplicate its
// definition for now.
#define ATTRIBUTE_UNUSED

#ifdef __GNUC__
#define LIBXSLT_ATTR_FORMAT(fmt, args)                                         \
  __attribute__((__format__(__printf__, fmt, args)))
#else
#define LIBXSLT_ATTR_FORMAT(fmt, args)
#endif

#if !defined LIBXSLT_PUBLIC
#if (defined(__CYGWIN__) || defined _MSC_VER) && !defined IN_LIBXSLT &&        \
    !defined LIBXSLT_STATIC
#define LIBXSLT_PUBLIC __declspec(dllimport)
#else
#define LIBXSLT_PUBLIC
#endif
#endif

#endif
