(* Your script goes here *)
(*
 *
 * iKATH - Skriptet som hjälper DIG att planera DITT Kathmandubesök
 *
 * Litet script som: 
 * - beräknar aktuell vecka
 * - hämtar och sparar ner aktuell meny från Kathmandu (udda eller jämn vecka)
 * - parsar html m.h.a. av xmllints xpath funktion
 * - presenterar resultat i en OSX-dialog
 * 
 * Skriptet distribueras som en .app men kan också användas i Automator som en tjänst för att t.ex. kunna aktiveras via 
 * snabbtangent (Tangentbord -> Kortkommandon). T.ex.:
 *     Shift + Option + Command + k
 *
 *)

set MENU_HTML to "menu.html"
set MENU_URL to "http://www.kathmandurestaurang.se/lunch.php"
set MEAT_ALT_1 to 1
set MEAT_ALT_2 to 2
set VEG_ALT to 3
set SCRIPT_NAME to "iKATH"
set LOGO to path to resource "nepal.png"
set LUNCH_DATE to (current date)
set WDAYS to {"Söndag", "Måndag", "Tisdag", "Onsdag", "Torsdag", "Fredag", "Lördag", "Söndag"}

on week(d)
	set ordinalDay to getOrdinalDay(d)
	set wDaySE to weekdaySE((weekday of d as integer))
	--return ordinalDay
	set w to (((ordinalDay as integer) - wDaySE as integer) + 10) div 7
	if w = 0 then
		--aktuellt datum hör till sista vecka i föregående år
		set d's day to 1
		return week(d - 24 * 60 * 60)
	else if w = 53 then
		--om den 1:a nästa år börjar på tors eller tidigare, räknas datumet till vecka 1 nästa år
		set d's year to (year of d) + 1
		set d's month to 1
		set d's day to 1
		if weekdaySE(weekday of d) ≤ 4 then
			return 1
		end if
	end if
	return w
end week

on lastDayOfMonth(m, d)
	set foo to date ("01-" & m + 1 & "-" & (year of d as string))
	return day of (foo - (24 * 60 * 60))
end lastDayOfMonth

on weekdaySE(wDay)
	return 1 + (wDay + 5) mod 7
end weekdaySE

on getOrdinalDay(d)
	set i to 1
	set sum to 0
	repeat (month of d) - 1 times
		set sum to sum + lastDayOfMonth(i, d)
		set i to i + 1
	end repeat
	return sum + (day of d)
end getOrdinalDay

--return bd
on scrape(xpath, scrapeURL, flag)
	set sed to ""
	if (flag = 1) then
		set sed to "sed 's/<b>[0-9. 	]*//g' | sed 's/<\\/b>/\\
	/g'  | sed 's/<[^>]*>//g'  | sed 's/[	]*//g' "
	else if (flag = 0) then
		set sed to "sed 's/^.*menu_bg.*$//g' | sed 's/<[^>]*>//g' | sed 's/^[	 ]*//g' "
	end if
	return do shell script "curl " & scrapeURL & " | xmllint --html --xpath '" & xpath & "' -" & " 2>dev/null | " & sed
	
end scrape



--hämta aktuell vecka
set wDay to weekday of (LUNCH_DATE + (0 * 60 * 60)) --för morgondagens datum gör t.ex. 24 * 60 * 60

--sätter index till motsvarande div-element för jämn resp. udda vecka...
if week(LUNCH_DATE) mod 2 = 0 then
	--jämn
	set katIndex to 1
else
	--udda
	set katIndex to 2
end if


if (wDay = Saturday or wDay = Sunday) then
	display dialog "Ingen lunch idag...det är helg!" buttons ("Ok") default button "Ok"
	return
else
	set wDay to item wDay of WDAYS
end if




--skrapa data
set xpath to "(//div[node() = \"" & wDay & "\"])[" & katIndex & "]/following-sibling::b"

set res to scrape(xpath, MENU_URL, 1)


set xpath to "//div[@class=\"category-desc clearfix\"]/*[not(self::comment())]"
set info to scrape(xpath, MENU_URL, 0)

--return res
set res to res & "



" & info


set _event to display dialog res with title SCRIPT_NAME & " // " & wDay & " på Kathmandu vecka " & week(LUNCH_DATE) buttons ({"Ok", "Kathmandu"}) default button "Ok" with icon LOGO

if button returned of _event = "Kathmandu" then
	tell application "Google Chrome"
		activate
		open location "http://kathmandurestaurang.se"
		delay 1
		activate
		
	end tell
end if
