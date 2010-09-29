%define ruby_sitelib %(ruby -rrbconfig -e "puts Config::CONFIG['sitelibdir']")
%define gemdir %(ruby -rubygems -e 'puts Gem::dir' 2>/dev/null)
%define gemname net-sshr
%define geminstdir %{gemdir}/gems/%{gemname}-%{version}

Summary: Flexible ssh wrapper to execute commands on remote hosts
Name: sshr
Version: 0.4
Release: 1%{?org_tag}%{?dist}
Group: Development/Languages
License: GPLv2+ or Ruby
URL: http://www.openfusion.net/tags/sshr
Source0: %{gemname}-%{version}.gem
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Requires: rubygems
Requires: rubygem(net-ssh) >= 0
Requires: rubygem(net-ssh-multi) >= 0
BuildRequires: rubygems, rdtool
BuildArch: noarch
Provides: rubygem(%{gemname}) = %{version}

%description
Flexible ssh wrapper to execute commands on remote hosts and 
render the output in nice ways.

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

# Create gemdir/ri symlinks
mkdir -p %{buildroot}%{gemdir}/ri
cd %{buildroot}%{gemdir}/ri 
for dir in ../doc/%{gemname}-%{version}/ri/*; do
  test -d $dir && ln -s $dir
done

%clean
rm -rf %{buildroot}

%files
%defattr(-, root, root, -)
%{_bindir}/*
%{gemdir}/gems/%{gemname}-%{version}/
%doc %{gemdir}/doc/%{gemname}-%{version}
%{gemdir}/cache/%{gemname}-%{version}.gem
%{gemdir}/specifications/%{gemname}-%{version}.gemspec
%{gemdir}/ri/*
%{_mandir}/man1/*

%changelog
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
