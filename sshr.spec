%define ruby_sitelib %(ruby -rrbconfig -e "puts Config::CONFIG['sitelibdir']")
%define gemdir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%define gemname net-sshr
%define geminstdir %{gemdir}/gems/%{gemname}-%{version}

Summary: Flexible ssh wrapper to execute commands on remote hosts
Name: sshr
Version: 0.8
Release: 1%{?org_tag}%{?dist}
Group: System/Application
License: GPLv2+ or Ruby
URL: http://www.openfusion.net/tags/sshr
Source0: %{gemname}-%{version}.gem
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildRequires: rubygems, rdtool
Requires: rubygem(%{gemname}) = %{version}
BuildArch: noarch

%description
Flexible ssh wrapper to execute commands on remote hosts and render the
output in nice ways.

%package -n rubygem-%{gemname}
Summary: SSH wrapper library to execute a command on multiple hosts
Group: Development/Languages
Requires: rubygems
Requires: rubygem(net-ssh) >= 0
Requires: rubygem(net-ssh-multi) >= 0
Provides: rubygem(%{gemname}) = %{version}

%description -n rubygem-%{gemname}
An ssh wrapper library optimised for executing one or more commands on 
multiple hosts.

%prep

%build

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}%{gemdir}
gem install --local --install-dir %{buildroot}%{gemdir} \
            --force --rdoc %{SOURCE0}
mkdir -p %{buildroot}/%{_bindir}
mv %{buildroot}%{gemdir}/bin/* %{buildroot}/%{_bindir}
rmdir %{buildroot}%{gemdir}/bin
find %{buildroot}%{geminstdir}/bin -type f | xargs chmod a+x

# Create a man page
mkdir -p %{buildroot}%{_mandir}/man1
rd2 -r rd/rd2man-lib.rb %{buildroot}%{geminstdir}/bin/sshr > %{buildroot}%{_mandir}/man1/sshr.1

%clean
rm -rf %{buildroot}

%files
%defattr(-, root, root, -)
%{_bindir}/*
%{_mandir}/man1/*

%files -n rubygem-%{gemname}
%defattr(-, root, root, -)
%{gemdir}/gems/%{gemname}-%{version}/
%doc %{gemdir}/doc/%{gemname}-%{version}
%{gemdir}/cache/%{gemname}-%{version}.gem
%{gemdir}/specifications/%{gemname}-%{version}.gemspec

%changelog
* Wed Dec 08 2010 Gavin Carr <gavin@openfusion.com.au> - 0.8-1
- Add a --user/-u option to sshr.
- Update sshr_exec to return a result list if no block given.
- Add a request_pty option to Net::SSHR and a corresponding -t to sshr
- Documentation and unit test updates.

* Thu Nov 25 2010 Gavin Carr <gavin@openfusion.com.au> - 0.7-1
- Split out into separate rubygem-net-sshr and sshr packages.

* Tue Oct 26 2010 Gavin Carr <gavin@openfusion.com.au> - 0.6.1-1
- Add non-blocking single-host version of sshr_exec.

* Tue Oct 26 2010 Gavin Carr <gavin@openfusion.com.au> - 0.6-1
- Simplify sshr_exec_list channel handling using Net::SSH::Multi :allow_duplicate_servers.
- Change sshr_exec_list interface to flattened list.

* Mon Oct 04 2010 Gavin Carr <gavin@openfusion.com.au> - 0.5-1
- Add sshr_exec_list method.
- Convert Net::SSHR from class to module.

* Wed Sep 29 2010 Gavin Carr <gavin@openfusion.com.au> - 0.4-1
- Turn results into a proper class.
- Tweak various interfaces to be more rubyesque.
- Add initial unit tests.

* Thu Sep 18 2010 Gavin Carr <gavin@openfusion.com.au> - 0.3-1
- Fix asynch bug due to extraneous channel.wait.

* Thu Sep 18 2010 Gavin Carr <gavin@openfusion.com.au> - 0.2-1
- Extensive refactoring, first real release.

* Mon Jun 28 2010 Gavin Carr <gavin@openfusion.com.au> - 0.1-1
- Initial package.
