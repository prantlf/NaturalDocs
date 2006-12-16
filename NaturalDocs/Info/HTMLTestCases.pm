###############################################################################
#
#   File: HTML Test Cases
#
###############################################################################
#
#   This file tests Natural Docs' generated output.  Particularly useful when testing various browsers.
#
###############################################################################

# This file is part of Natural Docs, which is Copyright (C) 2003-2006 Greg Valure
# Natural Docs is licensed under the GPL

use strict;
use integer;


#
#   About: Browsers
#
#   The specific browser versions tested are below.  Everything is tested on Windows XP unless otherwise noted.
#
#   - Firefox 2.0
#   - Firefox 1.5.0.8
#   - Firefox 1.0.8 (not important to support)
#
#   - IE 7
#   - IE 6
#   - IE 5.5 standalone hack (not important to support)
#   - IE 5.01 standalone hack (not important to support)
#
#   - Opera 9.02
#   - Opera 8.54
#   - Opera 8.02
#   - Opera 7.51 (not important to support)
#   - Opera 7.02 (not important to support)
#
#   - Konqueror 3.5.0 on SuSE Linux 10 via VMware Player
#


###############################################################################
# Group: Search

#
#   Topic: Unframed HTML Search
#
#   Tests:
#
#       - Make sure the search box appears and disappears correctly on hover.
#       - Type to bring up results.  Type further to narrow them.  Narrow until there's no results.
#       - Backspace to bring the results back.  Backspacing to empty closes the results.
#       - Type to bring up results with a different first letter.  (Tests iframe content switch.)
#       - Type *Z* to bring up empty page when there's nothing with that first letter.  (Tests generic no results page.)
#       - Type *Name* in Everything search to test expanding and collapsing, especially between two that differ only by case.
#       - Change filter to *Functions* to test changing filter while results are open.  Change to *Types* to switch to one with
#         no results.
#       - Test Close button on results.  Should deactivate panel as well.
#       - Clicking away should deactivate panel if the box is empty, not have an effect if there are results open.
#       - Text should always change back to "Search" when deactivating.
#
#   Results:
#
#       Last tested with November 19th, 2006 development release (1.35 base)
#
#       Firefox 2.0  - OK
#       Firefox 1.5  - OK
#       Firefox 1.0  - Results border and close button is limited to menu width.  IFrame shows entire width.  It's functional and the
#                           browser's old enough not to care.
#
#       IE 7.0  - OK
#       IE 6.0  - Controls don't appear on hover.  Bug in IE's hover handling, couldn't get around it.  Still functional and activates
#                    correctly on click, so acceptable.  Doesn't even look like a flaw to the user.
#       IE 5.5  - Surprisingly functional.  Hover doesn't work like in IE6.  Filter control doesn't show up at all.  Other visual flaws.
#                    Don't care.
#       IE 5.0  - Better than freaking 5.5!  Works as good as IE6!  Same hover bug, filter is a tiny bit too wide, but otherwise
#                    perfect.  Very unexpected.
#
#       Opera 9.0  - OK
#       Opera 8.5  - OK
#       Opera 8.0  - OK
#       Opera 7.5  - Sunken border when inactive.  Otherwise OK.
#       Opera 7.0  - Non-functional.  Don't care.
#
#       Konqueror 3.5  - Non-functional.
#

#
#   Topic: Framed HTML Search
#
#   Tests:
#
#       - Make sure the search box appears and disappears correctly on hover.
#       - Type to bring up results on right.  Type further to narrow them.  Narrow until there's no results.
#       - Backspace to bring the results back.
#       - Type to bring up results with a different first letter.  (Tests frame content switch.)
#       - Type *Z* to bring up empty page when there's nothing with that first letter.  (Tests generic no results page.)
#       - Type *Name* in Everything search to see that there's no collapsing in this mode.
#       - Change filter to *Functions* to test changing filter while results are open.  Change to *Types* to switch to one with
#         no results.
#       - Clicking away should deactivate panel.
#       - Clicking a result should deactivate panel and show up in correct frame.
#       - Text should always change back to "Search" when deactivating.
#
#   Results:
#
#       Last tested with November 19th, 2006 development release (1.35 base)
#
#       Firefox 2.0  - OK
#       Firefox 1.5  - OK
#       Firefox 1.0  - OK
#
#       IE 7.0  - OK
#       IE 6.0  - Doesn't hover (see <Unframed HTML Search>.)  Otherwise OK.
#       IE 5.5  - Doesn't hover and no filter bar.  Otherwise OK.
#       IE 5.0  - Doesn't hover.  Otherwise OK.
#
#       Opera 9.0  - OK
#       Opera 8.5  - OK
#       Opera 8.0  - OK
#       Opera 7.5  - Sunken border when inactive.  Otherwise OK.
#       Opera 7.0  - Sort of functional, but very flaky.  Don't care.
#
#       Konqueror 3.5  - Minor visual flaw on deactivate.  Otherwise OK.
#


###############################################################################
# Group: To Do
# Prototypes, wide code blocks and images



1;
