%define _unpackaged_files_terminate_build 1

%define api_version 1
%define minor_version 6
%define gir_name ApiBase

Name: libapi-base
Version: 1.6
Release: alt1

Summary: Base objects for API libraries on Vala
License: GPL-3.0-or-later
Group: System/Libraries
Url: https://altlinux.space/rirusha/libapi-base
Vcs: https://altlinux.space/rirusha/libapi-base.git

Source: %name-%version.tar
Patch: %name-%version-%release.patch

BuildRequires(pre): rpm-macros-meson
BuildRequires: rpm-build-vala
BuildRequires: rpm-build-gir
BuildRequires: meson
BuildRequires: vala
BuildRequires: pkgconfig(json-glib-1.0)
BuildRequires: gir(Json) = 1.0
BuildRequires: pkgconfig(gee-0.8)
BuildRequires: gir(Gee) = 0.8
BuildRequires: pkgconfig(gio-2.0)
BuildRequires: pkgconfig(libsoup-3.0)
BuildRequires: gir(Soup) = 3.0
BuildRequires: pkgconfig(json-glib-1.0)
BuildRequires: gobject-introspection-devel

%description
%summary.

%package -n %%name-%api_version
Summary: %{summary %name}
Group: System/Libraries

%description -n %%name-%api_version
%{description %name}.

%package -n %%name-%api_version-devel
Group: Development/Other
Summary: Headers files and library symbolic links for %name
Requires: %%name-%api_version = %EVR

%description -n %%name-%api_version-devel
%summary.
This package contains headers and libs
required for building programs with %name.

%package -n %%name-%api_version-gir
Summary: GObject introspection data for libapi-base
Group: System/Libraries
Requires: %%name-%api_version = %EVR

%description -n %%name-%api_version-gir
%{summary %%name-%api_version-gir}.

%package -n %%name-%api_version-gir-devel
Summary: GObject introspection devel data for libapi-base
Group: System/Libraries
BuildArch: noarch
Requires: %%name-%api_version-gir = %EVR
Requires: %%name-%api_version-devel = %EVR

%description -n %%name-%api_version-gir-devel
%{summary %%name-%api_version-gir-devel}.

%prep
%setup
%autopatch -p1

%build
%meson
%meson_build

%install
%meson_install
%find_lang %name

%files -n %%name-%api_version
%_libdir/libapi-base-%api_version.so.*

%files -n %%name-%api_version-devel
%_includedir/libapi-base-%api_version.h
%_libdir/libapi-base-%api_version.so
%_pkgconfigdir/libapi-base-%api_version.pc
%_datadir/vala/vapi/libapi-base-%api_version.deps
%_datadir/vala/vapi/libapi-base-%api_version.vapi

%files -n %%name-%api_version-gir
%_typelibdir/ApiBase-%api_version.typelib

%files -n %%name-%api_version-gir-devel
%_girdir/ApiBase-%api_version.gir

%changelog
* Sat Dec 14 2024 Alexey Volkov <qualimock@altlinux.org> 1.6-alt1
- Initial build for ALT
