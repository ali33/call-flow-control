-------------------------------------------------------------------------------
--                                                                           --
--                     Copyright (C) 2014-, AdaHeads K/S                     --
--                                                                           --
--  This is free software;  you can redistribute it and/or modify it         --
--  under terms of the  GNU General Public License  as published by the      --
--  Free Software  Foundation;  either version 3,  or (at your  option) any  --
--  later version. This library is distributed in the hope that it will be   --
--  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of  --
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     --
--  You should have received a copy of the GNU General Public License and    --
--  a copy of the GCC Runtime Library Exception along with this program;     --
--  see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see    --
--  <http://www.gnu.org/licenses/>.                                          --
--                                                                           --
-------------------------------------------------------------------------------

--  Reponse handler for hanging up a call.
--  This effectively kills the channel, regardless of state.
--
--  Parameters: None
--  Returns: HTTP 404 Not found and a JSON body if the call is not present.
--           HTTP 200 OK and a JSON body otherwise.

with AWS.Response,
     AWS.Status;

package Handlers.Call.Hangup is

   Package_Name : constant String := "Handlers.Call.Hangup";

   function Callback return AWS.Response.Callback;

private
   function Generate_Response (Request : AWS.Status.Data)
                               return AWS.Response.Data;
end Handlers.Call.Hangup;