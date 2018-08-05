#!/bin/bash
#Written by Gregory Danenberg, the script converts VM network layout to Physical network topology

for xml in `find . -name "*-UAF.xml"`; do
	sed -i -e 's/^\(\s*\)\(<Component Name=\"SEM-VM-NW-.*>\)/\1<!-- \2 -->/' \
		-e 's/\(\s*\).*\(Component Name="swp-NW-.*\)\s-->/\1<\2>/' $xml
	if [ $? -eq 0 ]; then
		echo " -U- Updated $xml "
	else
		echo " -ERROR - Failed to update $xml"
	fi
done
