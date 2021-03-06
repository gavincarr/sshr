%define gem_name net-sshr

Summary: Flexible ssh wrapper to execute commands on remote hosts
Name: sshr
Version: 0.14
Release: 2%{?org_tag}%{?dist}
Group: System/Application
License: GPLv2+ or Ruby
URL: http://www.openfusion.net/tags/sshr
Source0: %{gem_name}-%{version}.gem
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildRequires: rubygems
%if %{rhel} >= 7
BuildRequires: rubygem-rdtool
%else
BuildRequires: rdtool
%endif
Requires: rubygem(%{gem_name}) = %{version}
BuildArch: noarch

%description
Flexible ssh wrapper to execute commands on remote hosts and render the
output in nice ways.

%package -n rubygem-%{gem_name}
Summary: SSH wrapper library to execute a command on multiple hosts
Group: Development/Languages
Requires: rubygems
Requires: rubygem(net-ssh)
Requires: rubygem(net-ssh-multi)
Requires: rubygem(highline)
Provides: rubygem(%{gem_name}) = %{version}

%description -n rubygem-%{gem_name}
An ssh wrapper library optimised for executing one or more commands on 
multiple hosts.

%prep
gem unpack %{SOURCE0}
%setup -q -D -T -n  %{gem_name}-%{version}
gem spec %{SOURCE0} -l --ruby > %{gem_name}.gemspec

%build
# Create the gem as gem install only works on a gem file
gem build %{gem_name}.gemspec

# %%gem_install compiles any C extensions and installs the gem into ./%%gem_dir
# by default, so that we can move it into the buildroot in %%install
%gem_install

%install
mkdir -p %{buildroot}%{gem_dir}
mv ./%{gem_dir}/* %{buildroot}%{gem_dir}
#gem install --local --install-dir %{buildroot}%{gem_dir} --force --rdoc %{SOURCE0}
mkdir -p %{buildroot}/%{_bindir}
mv bin/* %{buildroot}/%{_bindir}

# Create a man page
mkdir -p %{buildroot}%{_mandir}/man1
rd2 -r rd/rd2man-lib.rb %{buildroot}%{gem_instdir}/bin/sshr > %{buildroot}%{_mandir}/man1/sshr.1

%files
%defattr(-, root, root, -)
%{_bindir}/*
%{_mandir}/man1/*

%files -n rubygem-%{gem_name}
%defattr(-, root, root, -)
%{gem_instdir}
%doc %{gem_dir}/doc/%{gem_name}-%{version}
%exclude %{gem_dir}/cache/%{gem_name}-%{version}.gem
%{gem_dir}/specifications/%{gem_name}-%{version}.gemspec

%changelog
* Sat Oct 31 2015 Gavin Carr <gavin@openfusion.com.au> 0.14-2
- Update spec file to use %gem_install in %build section.

* Tue Sep 22 2015 Gavin Carr <gavin@openfusion.com.au> 0.14-1
- Minor syntax updates for compatibility with ruby >= 1.9.

* Mon Jun 25 2012 Gavin Carr <gavin@openfusion.com.au> 0.13-1
- Add --prefix-hostname option (for use with --long) to sshr and formatter.

* Thu Jan 19 2012 Gavin Carr <gavin@openfusion.com.au> - 0.12.2-1
- Fix typo in sshr_exec_list verbose message.

* Fri Jan 13 2012 Gavin Carr <gavin@openfusion.com.au> - 0.12-1
- Tweak :quiet handling to also consider stderr.

* Thu Jan 12 2012 Gavin Carr <gavin@openfusion.com.au> - 0.11.2-1
- Tweaks to documentation.

* Wed Dec 15 2010 Gavin Carr <gavin@openfusion.com.au> - 0.11-1
- Change default sshr --short output back to showing hostnames.

* Tue Dec 14 2010 Gavin Carr <gavin@openfusion.com.au> - 0.10-1
- Add -q|--quiet option to sshr to omit hosts without output.
- Add -L|--list format option to sshr to list hostnames with output (cf. grep -l).
- Move sshr formatting tests to test_net_sshr_formatter.

* Fri Dec 10 2010 Gavin Carr <gavin@openfusion.com.au> - 0.9-2
- Add dependency on rubygem(highline).

* Thu Dec 09 2010 Gavin Carr <gavin@openfusion.com.au> - 0.9-1
- Monkey-patch Net::SSH::Config to get config User setting working with sshr.
- Change default sshr --short output to omit hostnames (like ssh).
- Add sshr --show-hostname and --no-hostname  options.
- Add -- host-command separator (as alternative to quoting cmd).

* Wed Dec 08 2010 Gavin Carr <gavin@openfusion.com.au> - 0.8.1-1
- Tweak Net::SSHR to use :default_user => ENV['SSHR_USER'] || ENV['USER'].

* Wed Dec 08 2010 Gavin Carr <gavin@openfusion.com.au> - 0.8-1
- Add a --user/-u option to sshr.
- Update sshr_exec to return a result list if no block given.
- Add a request_pty option to Net::SSHR and a corresponding -t to sshr.
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

* Sat Sep 18 2010 Gavin Carr <gavin@openfusion.com.au> - 0.3-1
- Fix asynch bug due to extraneous channel.wait.

* Sat Sep 18 2010 Gavin Carr <gavin@openfusion.com.au> - 0.2-1
- Extensive refactoring, first real release.

* Mon Jun 28 2010 Gavin Carr <gavin@openfusion.com.au> - 0.1-1
- Initial package.
