%define debug_package %{nil}
%define _enable_debug_packages 0

%define name SEM-UTILS

Summary:            SEM Scripts for Middleware(SEM) project
Name:           %{name}
Version:            %{_comp_version}
Release:            %{_comp_stf}
Source:             %{name}-%{version}-%{release}.tgz
License:  	    Copyright 2006 Comverse, Inc. All rights reserved
Vendor:             Comverse Inc.
Group:              Applications/System
Packager:           Gregory Danenberg <gregory.danenberg@comverse.com>
BuildRoot:      %{_builddir}/%{name}-%{version}-%{release}
requires:           swp-CSP-Base-Label

    
AutoReqProv: no

%description
SEM Scripts for Middleware(SEM) project

%prep
%setup -c -n %{name}/%{version}/%{release}

%build

%install
install -d $RPM_BUILD_ROOT/usr/cti/apps/sem-utils
install -d $RPM_BUILD_ROOT/usr/cti/apps/sem-utils/scripts
install -d $RPM_BUILD_ROOT/usr/cti/apps/sem-utils/scripts/install
install -d $RPM_BUILD_ROOT/usr/cti/apps/sem-utils/scripts/utils
install -d $RPM_BUILD_ROOT/usr/cti/apps/sem-utils/scripts/sanity
install -d $RPM_BUILD_ROOT/usr/cti/apps/sem-utils/monitor

cp -rf scripts/* $RPM_BUILD_ROOT/usr/cti/apps/sem-utils/scripts/
/bin/rm -rf $RPM_BUILD_ROOT/usr/cti/apps/sem-utils/scripts/TracesViewer/bin $RPM_BUILD_ROOT/usr/cti/apps/sem-utils/scripts/TracesViewer/ConfigFiles $RPM_BUILD_ROOT/usr/cti/apps/sem-utils/scripts/TracesViewer/src


#############################
%clean
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf "$RPM_BUILD_ROOT"

#############################
%post

if [ -f /tmp/.test_environment ]; then
	echo "-I- This is not a test system"
	/bin/rm -rf /usr/cti/apps/sem-utils/scripts/utils/TracesViewer
	find /usr/cti/apps/sem-utils/scripts/utils ! -name cdh_status.pl -type f -exec /bin/rm -f {} \;
fi

#############################
%preun

%postun

#############################
%files
%defattr(0750,root,admin)

/usr/cti/apps/sem-utils

