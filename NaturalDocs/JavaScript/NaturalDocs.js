// This file is part of Natural Docs, which is Copyright (C) 2003-2005 Greg Valure
// Natural Docs is licensed under the GPL

//
//  Browser Styles
// ____________________________________________________________________________

var agt=navigator.userAgent.toLowerCase();
var browserType;
var browserVer;

if (agt.indexOf("opera") != -1)
    {
    browserType = "Opera";

    if (agt.indexOf("opera 5") != -1 || agt.indexOf("opera/5") != -1)
        {  browserVer = "Opera5";  }
    else if (agt.indexOf("opera 6") != -1 || agt.indexOf("opera/6") != -1)
        {  browserVer = "Opera6";  }
    else if (agt.indexOf("opera 7") != -1 || agt.indexOf("opera/7") != -1)
        {  browserVer = "Opera7";  }
    else if (agt.indexOf("opera 8") != -1 || agt.indexOf("opera/8") != -1)
        {  browserVer = "Opera8";  }
    else if (agt.indexOf("opera 9") != -1 || agt.indexOf("opera/9") != -1)
        {  browserVer = "Opera9";  }
    }

else if (agt.indexOf("khtml") != -1 || agt.indexOf("konq") != -1 || agt.indexOf("safari") != -1 || agt.indexOf("applewebkit") != -1)
    {
    browserType = "KHTML";
    }

else if (agt.indexOf("msie") != -1)
    {
    browserType = "IE";

    if (agt.indexOf("msie 5") != -1)
        {  browserVer = "IE5";  }
    else if (agt.indexOf("msie 6") != -1)
        {  browserVer = "IE6";  }
    else if (agt.indexOf("msie 7") != -1)
        {  browserVer = "IE7";  }
    }

else if (agt.indexOf("gecko") != -1)
    {
    browserType = "Firefox";

    if (agt.indexOf("rv:1.7") != -1)
        {  browserVer = "Firefox1";  }
    else if (agt.indexOf("rv:1.8") != -1)
        {  browserVer = "Firefox15";  }
    }


//
//  Support Functions
// ____________________________________________________________________________


function GetXPosition(item)
    {
    var position = 0;

    if (item.offsetWidth != null && browserVer != "Opera5")
        {
        while (item != document.body && item != null)
            {
            position += item.offsetLeft;
            item = item.offsetParent;
            };
        };

    return position;
    };


function GetYPosition(item)
    {
    var position = 0;

    if (item.offsetWidth != null && browserVer != "Opera5")
        {
        while (item != document.body && item != null)
            {
            position += item.offsetTop;
            item = item.offsetParent;
            };
        };

    return position;
    };


function MoveToPosition(item, x, y)
    {
    // Opera 5 chokes on the px extension, so it can use the Microsoft one instead.

    if (item.style.left != null && browserVer != "Opera5")
        {
        item.style.left = x + "px";
        item.style.top = y + "px";
        }
    else if (item.style.pixelLeft != null)
        {
        item.style.pixelLeft = x;
        item.style.pixelTop = y;
        };
    };


//
//  Menu
// ____________________________________________________________________________


function ToggleMenu(id)
    {
    if (!window.document.getElementById)
        {  return;  };

    var display = window.document.getElementById(id).style.display;

    if (display == "none")
        {  display = "block";  }
    else
        {  display = "none";  }

    window.document.getElementById(id).style.display = display;
    }


//
//  Tooltips
// ____________________________________________________________________________


var tooltipTimer = 0;

function ShowTip(event, tooltipID, linkID)
    {
    if (tooltipTimer)
        {  clearTimeout(tooltipTimer);  };

    var docX = event.clientX + window.pageXOffset;
    var docY = event.clientY + window.pageYOffset;

    var showCommand = "ReallyShowTip('" + tooltipID + "', '" + linkID + "', " + docX + ", " + docY + ")";

    tooltipTimer = setTimeout(showCommand, 1000);
    }

function ReallyShowTip(tooltipID, linkID, docX, docY)
    {
    tooltipTimer = 0;

    var tooltip;
    var link;

    if (document.getElementById)
        {
        tooltip = document.getElementById(tooltipID);
        link = document.getElementById(linkID);
        }
/*    else if (document.all)
        {
        tooltip = eval("document.all['" + tooltipID + "']");
        link = eval("document.all['" + linkID + "']");
        }
*/
    if (tooltip)
        {
        var left = GetXPosition(link);
        var top = GetYPosition(link);
        top += link.offsetHeight;


        // The fallback method is to use the mouse X and Y relative to the document.  We use a separate if and test if its a number
        // in case some browser snuck through the above if statement but didn't support everything.

        if (!isFinite(top) || top == 0)
            {
            left = docX;
            top = docY;
            }

        // Some spacing to get it out from under the cursor.

        top += 10;

        // Make sure the tooltip doesnt get smushed by being too close to the edge, or in some browsers, go off the edge of the
        // page.  We do it here because Konqueror does get offsetWidth right even if it doesnt get the positioning right.

        if (tooltip.offsetWidth != null)
            {
            var width = tooltip.offsetWidth;
            var docWidth = document.body.clientWidth;

            if (left + width > docWidth)
                {  left = docWidth - width - 1;  }

            // If there's a horizontal scroll bar we could go past zero because it's using the page width, not the window width.
            if (left < 0)
                {  left = 0;  };
            }

        MoveToPosition(tooltip, left, top);
        tooltip.style.visibility = "visible";
        }
    }

function HideTip(tooltipID)
    {
    if (tooltipTimer)
        {
        clearTimeout(tooltipTimer);
        tooltipTimer = 0;
        }

    var tooltip;

    if (document.getElementById)
        {  tooltip = document.getElementById(tooltipID); }
    else if (document.all)
        {  tooltip = eval("document.all['" + tooltipID + "']");  }

    if (tooltip)
        {  tooltip.style.visibility = "hidden";  }
    }


//
//  Image Popup
// ____________________________________________________________________________


var undefined;
var popupWindowNumber = 1;

function ImagePopup(popupPageURL, popupImageURL, width, height, title)
    {
    var scrollbars = 0;

    if (width > (screen.availWidth * 0.8))
        {
        width = (screen.availWidth * 0.8);
        scrollbars = 1;
        }
    if (height > (screen.availHeight * 0.8))
        {
        height = (screen.availHeight * 0.8);
        scrollbars = 1;
        }

    var windowHandle = window.open(popupPageURL + '?' + popupImageURL + ',' + title,
                                                      'NDImagePopupWindow' + popupWindowNumber,
                                                      'status=0,toolbar=0,location=0,menubar=0,directories=0,resizable=1,'
                                                       + 'scrollbars=' + scrollbars + ',width=' + width + ',height=' + height);

    windowHandle.moveTo( (screen.availWidth - width) / 2, (screen.availHeight - height) / 2 );
    popupWindowNumber++;
    }



//
//  Blockquote fix for IE
// ____________________________________________________________________________


function NDOnLoad()
    {
    if (browserType == "IE")
        {
        var scrollboxes = document.getElementsByTagName('blockquote');

        if (scrollboxes.item(0))
            {
            NDDoResize();
            window.onresize=NDOnResize;
            };
        };
    };


var resizeTimer = 0;

function NDOnResize()
    {
    if (resizeTimer != 0)
        {  clearTimeout(resizeTimer);  };

    resizeTimer = setTimeout(NDDoResize, 250);
    };


function NDDoResize()
    {
    var scrollboxes = document.getElementsByTagName('blockquote');

    var i;
    var item;

    i = 0;
    while (item = scrollboxes.item(i))
        {
        item.style.width = 100;
        i++;
        };

    i = 0;
    while (item = scrollboxes.item(i))
        {
        item.style.width = item.parentNode.offsetWidth;
        i++;
        };

    clearTimeout(resizeTimer);
    resizeTimer = 0;
    }


//
//  Search Results Page
// ____________________________________________________________________________


function SRToggleSubMenu(id)
    {
    var parentElement = document.getElementById(id);

    var element = parentElement.firstChild;

    while (element != null && element != parentElement)
        {
        if (element.nodeName == 'DIV' && element.className == 'ISubIndex')
            {
            if (element.style.display == 'block')
                {  element.style.display = "none";  }
            else
                {  element.style.display = 'block';  }
            };

        if ( element.nodeName == 'DIV' && element.hasChildNodes() )
            {  element = element.firstChild;  }
        else if (element.nextSibling != null)
            {  element = element.nextSibling;  }
        else
            {
            do
                {
                element = element.parentNode;
                }
            while (element != null && element != parentElement && element.nextSibling == null);

            if (element != null && element != parentElement)
                {  element = element.nextSibling;  };
            };
        };
    };


function SRSearch()
    {
    var search = window.location.search;

    search = search.substring(1);  // Remove the leading ?
    search = unescape(search);
    search = search.replace(/^ +/, "");
    search = search.replace(/ +$/, "");
    search = search.toLowerCase();

    search = search.replace(/\_/g, "_und");
    search = search.replace(/\ +/gi, "_spc");
    search = search.replace(/\~/g, "_til");
    search = search.replace(/\!/g, "_exc");
    search = search.replace(/\@/g, "_att");
    search = search.replace(/\#/g, "_num");
    search = search.replace(/\$/g, "_dol");
    search = search.replace(/\%/g, "_pct");
    search = search.replace(/\^/g, "_car");
    search = search.replace(/\&/g, "_amp");
    search = search.replace(/\*/g, "_ast");
    search = search.replace(/\(/g, "_lpa");
    search = search.replace(/\)/g, "_rpa");
    search = search.replace(/\-/g, "_min");
    search = search.replace(/\+/g, "_plu");
    search = search.replace(/\=/g, "_equ");
    search = search.replace(/\{/g, "_lbc");
    search = search.replace(/\}/g, "_rbc");
    search = search.replace(/\[/g, "_lbk");
    search = search.replace(/\]/g, "_rbk");
    search = search.replace(/\:/g, "_col");
    search = search.replace(/\;/g, "_sco");
    search = search.replace(/\"/g, "_quo");
    search = search.replace(/\'/g, "_apo");
    search = search.replace(/\</g, "_lan");
    search = search.replace(/\>/g, "_ran");
    search = search.replace(/\,/g, "_com");
    search = search.replace(/\./g, "_per");
    search = search.replace(/\?/g, "_que");
    search = search.replace(/\//g, "_sla");
    search = search.replace(/[^a-z0-9\_]i/gi, "_zzz");

    search = "sr_" + search;

    var resultRows = document.getElementsByTagName("div");
    var matches = 0;

    var i = 0;
    while (i < resultRows.length)
        {
        var row = resultRows.item(i);

        if (row.className == "SRResult" &&
            search.length <= row.id.length && row.id.substr(0, search.length).toLowerCase() == search)
            {
            row.style.display="block";
            matches++;
            }

        i++;
        };

    document.getElementById("Searching").style.display="none";

    if (matches == 0)
        {  document.getElementById("NoMatches").style.display="block";  }
    };



//
//  Search Controls on Menu
// ____________________________________________________________________________


var lastSearchValue ="";
var searchTimer = 0;

function SearchFieldOnFocus(active)
    {
    CheckSearchActive(active);
    };

function SearchTypeOnFocus(active)
    {
    CheckSearchActive(active);
    };

function SearchFieldOnChange()
    {
    var searchField = document.getElementById("MSearchField");

    if (searchTimer)
        {
        clearTimeout(searchTimer);
        searchTimer = 0;
        };

    var search = searchField.value.replace(/ +/g, "");

    if (search != lastSearchValue)
        {
        if (search != "")
            {
            searchTimer = setTimeout("NDSearch()", 500);
            }
        else
            {
            document.getElementById("MSearchResultsWindow").style.display = "none";
            lastSearchValue="";
            };
        };
    };

function SearchTypeOnChange()
    {
    var searchField = document.getElementById("MSearchField");

    var search = searchField.value.replace(/ +/g, "");

    if (search != "")
        {
        NDSearch();
        };
    };

function CloseSearchResults()
    {
    document.getElementById("MSearchResultsWindow").style.display = "none";
    CheckSearchActive(0);
    };

function NDSearch()
    {
    searchTimer = 0;

    var searchField = document.getElementById("MSearchField");
    var typeField = document.getElementById("MSearchType");
    var results = document.getElementById("MSearchResults");
    var resultsWindow = document.getElementById("MSearchResultsWindow");

    var search = searchField.value.replace(/^ +/, "");

    var filePath = typeField.value;

    var pageExtension = search.substr(0,1);

    if (pageExtension.match(/^[a-z]/i))
        {  pageExtension = pageExtension.toUpperCase();  }
    else if (pageExtension.match(/^[0-9]/))
        {  pageExtension = 'Numbers';  }
    else
        {  pageExtension = "Symbols";  };

    var page = filePath.replace(/\*/, pageExtension);


    var left = GetXPosition(typeField);
    var top = GetYPosition(typeField) + searchField.offsetHeight;

    MoveToPosition(resultsWindow, left, top);
    results.innerHTML = '<iframe src="'+page+'?'+escape(searchField.value)+'" frameborder=0>';
    resultsWindow.style.display = 'block';

    lastSearchValue = searchField.value;
    };


var searchInactiveTimer = 0;

function CheckSearchActive(focus)
    {
    var searchPanel = document.getElementById("MSearchPanel");
    var resultsWindow = document.getElementById("MSearchResultsWindow");
    var searchField = document.getElementById("MSearchField");

    if (focus || resultsWindow.style.display == "block")
        {
        searchPanel.className = 'MSearchPanelActive';

        if (searchField.value == 'Search')
             {  searchField.value = "";  }

        if (searchInactiveTimer)
            {
            clearTimeout(searchInactiveTimer);
            searchInactiveTimer = 0;
            };
        }
    else
        {
        searchInactiveTimer = setTimeout("MakeSearchInactive()", 200);
        };
    };

// This method is necessary because when switching focus from one control to another, we don't want it to deactivate because
// then it would replace the search value when we don't want it to.
function MakeSearchInactive()
    {
    var searchPanel = document.getElementById("MSearchPanel");
    var searchField = document.getElementById("MSearchField");

    searchInactiveTimer = 0;

    searchPanel.className = 'MSearchPanelInactive';
    searchField.value = "Search";
    };
