/* vim: syntax=verilog
This file is part of verilog-buildingblocks,
by David R. Piegdon <dgit@piegdon.de>

verilog-buildingblocks is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

verilog-buildingblocks is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with verilog-buildingblocks.  If not, see <https://www.gnu.org/licenses/>.
*/

/*
 * Console-related helper methods to improve verilog
 * compiler output, linting, debugging etc.
 * To use, `include it in your module.
 */

/* ANSI COLOR CODES
 * FG  BG  COLOR
 * --- --- --------
 * 30  40  black
 * 31  41  red
 * 32  42  green
 * 33  43  yellow
 * 34  44  blue
 * 35  45  magenta
 * 36  46  cyan
 * 37  47  white
 *
 * ANSI STYLE CODES
 * 0: normal
 * 1: bold
 * 2: low intensity
 * 4: underline
 * 5: blink
 * 7: inverse
 * 8: invisible
 */

`define CON_BOLD_RED     	"\033[1;31m"
`define CON_BOLD_YELLOW  	"\033[1;33m"
`define CON_RST          	"\033[0m"

`define WARNING(msg)		$warning({`CON_BOLD_YELLOW, msg, `CON_RST})
`define ERROR(msg)		$error({`CON_BOLD_RED, msg, `CON_RST})
