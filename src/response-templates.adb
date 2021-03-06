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

with Black.HTTP,
     Black.MIME_Types;

package body Response.Templates is

   procedure Add_CORS_Headers
     (Request  : in     Black.Request.Class;
      Response : in out Black.Response.Class)
   is
      use Black.HTTP, Black.Response.Access_Control;
   begin
      if Request.Has_Origin then
         Allow_Origin      (Response, Request.Origin);
         Allow_Credentials (Response);
         Allow_Headers     (Response, (Get | Post => True,
                                       others     => False));
         Max_Age           (Response, 86_400.0);
      end if;
   end Add_CORS_Headers;

   ----------------------
   --  Bad_Parameters  --
   ----------------------

   function Bad_Parameters (Request       : in Black.Request.Instance;
                            Response_Body : in JSON_Value := Create_Object)
                           return Black.Response.Instance is
   begin
      Response_Body.Set_Field (Status_Text, Bad_Parameters_Response_Text);

      return Response : Black.Response.Instance :=
        Black.Response.Bad_Request
          (Content_Type => Black.MIME_Types.Application.JSON,
           Data         => Response_Body.Write)
      do
         Add_CORS_Headers (Request  => Request,
                           Response => Response);
      end return;
   end Bad_Parameters;

   function Forbidden (Request       : in Black.Request.Instance;
                       Response_Body : in JSON_Value := Create_Object)
                      return Black.Response.Instance is
   begin
      Response_Body.Set_Field (Status_Text, Forbidden_Response_Text);

      return Response : Black.Response.Instance :=
        Black.Response.Forbidden
          (Content_Type => Black.MIME_Types.Application.JSON,
           Data         => Response_Body.Write)
      do
         Add_CORS_Headers (Request  => Request,
                           Response => Response);
      end return;
   end Forbidden;

   ----------------------
   --  Not_Authorized  --
   ----------------------

   function Not_Authorized (Request : in Black.Request.Instance)
                           return Black.Response.Instance is
      Response_Body : constant JSON_Value := Create_Object;
   begin
      Response_Body.Set_Field (Status_Text, Not_Authorized_Response_Text);

      return Response : Black.Response.Instance :=
        Black.Response.Unauthorized
          (Content_Type => Black.MIME_Types.Application.JSON,
           Data         => Response_Body.Write)
      do
         Add_CORS_Headers (Request  => Request,
                           Response => Response);
      end return;
   end Not_Authorized;

   -----------------
   --  Not_Found  --
   -----------------

   function Not_Found (Request       : in Black.Request.Instance;
                       Response_Body : in JSON_Value := Create_Object)
                      return Black.Response.Instance is
   begin
      Response_Body.Set_Field (Status_Text, Not_Found_Response_Text);

      return Response : Black.Response.Instance :=
        Black.Response.Not_Found
          (Content_Type => Black.MIME_Types.Application.JSON,
           Data         => Response_Body.Write)
      do
         Add_CORS_Headers (Request  => Request,
                           Response => Response);
      end return;
   end Not_Found;

   ----------
   --  OK  --
   ----------

   function OK (Request       : in Black.Request.Instance;
                Response_Body : in JSON_Value := Create_Object)
               return Black.Response.Instance is
      Content : constant JSON_Value := Response_Body;
   begin
      Content.Set_Field (Status_Text, OK_Response_Text);

      return Response : Black.Response.Instance :=
        Black.Response.OK (Content_Type => Black.MIME_Types.Application.JSON,
                           Data         => Response_Body.Write)
      do
         Add_CORS_Headers (Request  => Request,
                           Response => Response);
      end return;
   end OK;

   --------------------
   --  Server_Error  --
   --------------------

   function Server_Error (Request       : in Black.Request.Instance;
                          Response_Body : in JSON_Value := Create_Object)
                         return Black.Response.Instance is
      pragma Unreferenced (Request);
      --  Why don't we include something from the request in the response?

      Content : constant JSON_Value := Response_Body;
   begin
      Content.Set_Field (Status_Text, Server_Error_Response_Text);

      return Black.Response.Server_Error
               (Content_Type => Black.MIME_Types.Application.JSON,
                Data         => Content.Write);
   end Server_Error;

end Response.Templates;
