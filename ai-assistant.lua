local ulf = {}
ulf.lib = require("ulf.lib")

local OUT_FILE = ".ai-update"
---@type string[]
local LINES = {}
local project_name = "b64tm"

local config = {

	path_code = "./lua/ulf/lib/conf",
	path_tests = "./spec/tests/ulf/lib/conf",
	prompt = {
		de = {
			[[
Prompt für Kommunikation mit ChatGPT:

	1.	Keine zusätzlichen Vorschläge oder Informationen ohne ausdrückliche Nachfrage: Liefere Vorschläge oder zusätzliche Informationen nur, wenn ich ausdrücklich darum bitte, um den Fokus zu wahren.
	2.	Kritische Perspektive nur auf ausdrücklichen Wunsch: Wenn ich um eine kritische Überprüfung bitte, weise gezielt auf mögliche Schwachstellen und Verbesserungen hin – wie es ein Partner oder Teamkollege tun würde.
	3.	Kommentare und Code ausschließlich auf Englisch: Verfasse Kommentare im Code immer auf Englisch, um internationale Verständlichkeit zu gewährleisten.
	4.	Knappe und präzise Kommunikation: Halte Antworten auf das Wesentliche beschränkt, um Reizüberflutung zu vermeiden und klare Struktur beizubehalten.
	5.	Bei <ASSISTANT_UPDATE> folgt aktueller Projektcode: Wenn <ASSISTANT_UPDATE> erscheint, wird der aktuelle Projektcode bereitgestellt. Verwende diesen als Referenz.
      ]],
		},

		en = [[
Prompt for Communication with ChatGPT:

	1.	No additional suggestions or information unless explicitly requested: Only provide suggestions or extra information if I specifically ask for it, to maintain focus.
	2.	Critical perspective only upon explicit request: When I request a critical review, specifically highlight potential weaknesses or improvements, as a teammate or partner would.
	3.	Comments and code exclusively in English: Write all comments in code in English to ensure international readability and best practices.
	4.	Concise and precise communication: Keep responses focused on essentials to avoid information overload and maintain clear structure.
	5.	Use <ASSISTANT_UPDATE> for current project code: When <ASSISTANT_UPDATE> appears, it will be followed by the current project code. Use this as a reference.
    ]],
	},
}

local function write_prompt()
	local prompt = config.prompt.de
	for line in prompt:gmatch("([^\n]*)\n?") do
		table.insert(LINES, line)
	end
end
local function add_code_dir(path)
	LINES[#LINES + 1] = string.format("<ASSISTANT_UPDATE>\n")

	ulf.lib.fs.ls(path, function(path, name, type)
		LINES[#LINES + 1] = string.format("-- >>>>>>>>>>>>>>>>>> BEGIN FILE %s\n", path)
		if type == "file" and name ~= "README.md" then
			local content = ulf.lib.fs.read_file(path)
			for line in content:gmatch("([^\n]*)\n?") do
				table.insert(LINES, line)
			end
		else
			LINES[#LINES + 1] = string.format("-- module directory of: %s", path)
		end

		LINES[#LINES + 1] = ""
		LINES[#LINES + 1] = string.format("-- >>>>>>>>>>>>>>>>>> BEGIN FILE %s\n", path)
	end)
end
-- write_prompt()
add_code_dir(config.path_code)
add_code_dir(config.path_tests)

local data = table.concat(LINES, "\n")
ulf.lib.fs.write_file(OUT_FILE, data)
