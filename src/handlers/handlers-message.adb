-------------------------------------------------------------------------------
--                                                                           --
--                     Copyright (C) 2013-, AdaHeads K/S                     --
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

with AWS.Status,
     GNATCOLL.JSON;

with Common,
     HTTP_Codes,
     MIME_Types,
     View;

package body Handlers.Message is
   package body Send is
      function Service (Request : in AWS.Status.Data) return AWS.Response.Data;

      function Callback return AWS.Response.Callback is
      begin
         return Service'Access;
      end Callback;

      function Service (Request : in AWS.Status.Data)
                       return AWS.Response.Data is
         use GNATCOLL.JSON;
         use Common;

         function Parameters_Okay return Boolean;
         function Bad_Parameters return AWS.Response.Data;
         function Not_Implemented return AWS.Response.Data;

         function Bad_Parameters return AWS.Response.Data is
            Data : JSON_Value;
         begin
            Data := Create_Object;

            Data.Set_Field (Field_Name => View.Status,
                            Field      => "bad parameters");

            return AWS.Response.Build
              (Content_Type => MIME_Types.JSON,
               Message_Body => To_String (To_JSON_String (Data)),
               Status_Code  => HTTP_Codes.Bad_Request);
         end Bad_Parameters;

         function Not_Implemented return AWS.Response.Data is
            Data : JSON_Value;
         begin
            Data := Create_Object;

            Data.Set_Field (Field_Name => View.Status,
                            Field      => "not implemented yet");

            return AWS.Response.Build
              (Content_Type => MIME_Types.JSON,
               Message_Body => To_String (To_JSON_String (Data)),
               Status_Code  => HTTP_Codes.Server_Error);
         end Not_Implemented;

         function Parameters_Okay return Boolean is
            use AWS.Status;
         begin
            return
              Parameters (Request).Count = 2 and then
              Parameters (Request).Exist ("cm_id") and then
              Parameters (Request).Exist ("msg");
         exception
            when others =>
               return False;
         end Parameters_Okay;

      begin
         if Parameters_Okay then
            return Not_Implemented;
         else
            return Bad_Parameters;
         end if;
      end Service;
   end Send;
end Handlers.Message;