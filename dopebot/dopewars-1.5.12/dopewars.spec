Summary:       Drug dealing game
Name:          dopewars
Version:       1.5.12
Release:       1
Vendor:        Ben Webb <benwebb@users.sf.net>
URL:           http://dopewars.sourceforge.net/
License:       GPL
Group:         Amusements/Games
Source0:       %{name}-%{version}.tar.gz
Obsoletes:     dopewars-esd = 1.5.7
BuildRoot:     %{_tmppath}/%{name}-%{version}-root-%(id -u -n)
BuildRequires: SDL_mixer-devel, SDL-devel, esound-devel

%description
Based on John E. Dell's old Drug Wars game, dopewars is a simulation of an    
imaginary drug market.  dopewars is an All-American game which features       
buying, selling, and trying to get past the cops!                              
                                                                                
The first thing you need to do is pay off your debt to the Loan Shark. After   
that, your goal is to make as much money as possible (and stay alive)! You     
have one month of game time to make your fortune.                              

dopewars supports multiple players via. TCP/IP. Chatting to and fighting
with other players (computer or human) is supported; check the command line
switches (via dopewars -h) for further information. 

%package sdl
Summary:  dopewars SDL_mixer sound plugin
Group:    Amusements/Games
Requires: %{name}
%description sdl
This package adds a plugin to dopewars to allow sound to be output via.
the Simple DirectMedia Layer mixer (SDL_mixer).

%prep
%setup

%build
%define _localstatedir /var/lib/games
%configure --with-sdl --with-esd
make

%install
make install DESTDIR=${RPM_BUILD_ROOT}
%find_lang %{name}

%clean
test "$RPM_BUILD_ROOT" != "/" && rm -rf ${RPM_BUILD_ROOT}

%post
%{_bindir}/dopewars -C %{_localstatedir}/dopewars.sco

%files -f %{name}.lang
%defattr(-,root,root)
%doc ChangeLog LICENCE README doc/aiplayer.html doc/clientplay.html
%doc doc/configfile.html doc/contribute.html doc/credits.html
%doc doc/developer.html doc/example-cfg doc/i18n.html doc/index.html
%doc doc/installation.html doc/metaserver.html doc/server.html
%doc doc/servercommands.html doc/protocol.html doc/windows.html
%attr(2755,root,games) %{_bindir}/dopewars
%attr(0660,root,games) %config %{_localstatedir}/dopewars.sco
%{_mandir}/man6/dopewars.6.gz
%{_libdir}/dopewars/libsound_esd.so
%{_datadir}/gnome/apps/Games/dopewars.desktop
%{_datadir}/pixmaps/dopewars-pill.png
%{_datadir}/pixmaps/dopewars-weed.png
%{_datadir}/pixmaps/dopewars-shot.png
%dir %{_datadir}/dopewars/
%{_datadir}/dopewars/bye.wav
%{_datadir}/dopewars/colt.wav
%{_datadir}/dopewars/die.wav
%{_datadir}/dopewars/gun.wav
%{_datadir}/dopewars/jet.wav
%{_datadir}/dopewars/losebitch.wav
%{_datadir}/dopewars/message.wav
%{_datadir}/dopewars/murmur.wav
%{_datadir}/dopewars/punch.wav
%{_datadir}/dopewars/run.wav
%{_datadir}/dopewars/shotdown.wav
%{_datadir}/dopewars/train.wav

%files sdl
%defattr(-,root,root)
%{_libdir}/dopewars/libsound_sdl.so

%changelog
* Mon Jul 28 2003 Ben Webb <benwebb@users.sf.net>
- High score file moved to /var/lib/games for consistency with
  other packages

* Mon Oct 21 2002 Ben Webb <benwebb@users.sf.net>
- Dependency on SDL-devel added to properly build SDL plugin

* Fri Oct 18 2002 Ben Webb <benwebb@users.sf.net>
- ESD plugin incorporated into main package
- Sound files added to distribution

* Fri Jun 21 2002 Ben Webb <benwebb@users.sf.net>
- Description typos corrected
- A lot of hardcoded texts replaced with %{name} etc.
- Redundant make arguments removed

* Mon May 13 2002 Ben Webb <benwebb@users.sf.net>
- SDL and ESD plugin subpackages added

* Sun Feb 03 2002 Ben Webb <benwebb@users.sf.net>
- Use of %attr tidied up
- Rebuild with new version

* Wed Oct 17 2001 Ben Webb <benwebb@users.sf.net>
- Added in %attrs to allow building by non-root users

* Wed Sep 26 2001 Ben Webb <benwebb@users.sf.net>
- Added support for a buildroot
