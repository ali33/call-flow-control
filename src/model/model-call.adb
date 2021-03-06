-------------------------------------------------------------------------------
--                                                                           --
--                     Copyright (C) 2012-, AdaHeads K/S                     --
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

with Ada.Characters.Handling,
     Ada.Strings,
     Ada.Strings.Fixed;
with Client_Notification,
     Model.User,
     Notification,
     System_Messages,
     View;

package body Model.Call is

   --------------------
   --  Arrival_Time  --
   --------------------

   function Arrival_Time (Obj : in Instance) return Common.Time is
   begin
      return Obj.Arrived;
   end Arrival_Time;

   -------------------
   --  Assign_Call  --
   -------------------

   procedure    Assign_Call
     (To   : in     Model.User_Identifier;
      Call :    out Model.Call.Instance;
      ID   : in     Model.Call.Identification :=
        Model.Call.Null_Identification) is
   begin
      Call_List.Assign_Call (To   => To,
                             ID   => ID,
                             Call => Call);
      Model.User.Assign_Call (User_ID => To,
                              Call_ID => Call.ID);
   end Assign_Call;

   -------------------
   --  Assigned_To  --
   -------------------

   function Assigned_To (Obj : in Instance) return User_Identifier is
   begin
      return Obj.Assigned_To;
   end Assigned_To;

   -------------
   --  B_Leg  --
   -------------

   function B_Leg (Obj : in Instance) return Identification is
   begin
      return Obj.B_Leg;
   end B_Leg;

   --------------------
   --  Change_State  --
   --------------------

   procedure Change_State (Obj : in Instance; New_State : in States) is
      Context    : constant String := Package_Name & ".Change_State";
      Last_State : constant States := Get (Obj.ID).State;
      --  Excessive cyclomatic complexity: State machine.
   begin
      System_Messages.Debug
        (Message => "UUID:" & Obj.ID.Image & "=>" &
           Last_State'Img & " -> " & New_State'Img,
         Context => Context);

      --  Update the state to make the call state reflect the actual state.
      Call_List.Change_State (Obj.ID, New_State);

      --  Assert that the call leaves a queue or a parking lot.
      if Last_State = Queued then
         Notification.Broadcast
           (Client_Notification.Leave (Get (Obj.ID)).To_JSON);
      elsif Last_State = Parked then
         Notification.Broadcast
           (Client_Notification.Unpark (Get (Obj.ID)).To_JSON);
      end if;

      case New_State is
         --  Upon creation, a
         when Created =>
            Notification.Broadcast
              (Client_Notification.Call_Offer (Get (Obj.ID)).To_JSON);

         --  Parking will merely cause a notification to be sent out.
         --  The event should, however, only  be sent to the client currently
         --  assigned to the call.
         when Parked =>
            Notification.Broadcast
              (Client_Notification.Park
                 (C => Get (Obj.ID)).To_JSON);

         when Unparked =>
            Notification.Broadcast
              (Client_Notification.Unpark (Get (Obj.ID)).To_JSON);

         when Queued =>
            Notification.Broadcast
              (Client_Notification.Join
                 (Get (Call => Obj.ID)).To_JSON);

         when Hungup =>
            if Get (Obj.ID).Is_Call then
               Notification.Broadcast
                 (Client_Notification.Hangup (Get (Obj.ID)).To_JSON);
            end if;

            Call_List.Remove (ID => Obj.ID);

         when Speaking =>
            if Get (Obj.ID).Is_Call then
               Notification.Broadcast
                 (Client_Notification.Pickup (Get (Obj.ID)).To_JSON);
            end if;

         when Transferred =>
            Notification.Broadcast
              (Client_Notification.Call_Transfer (Get (Obj.ID)).To_JSON);

         when Left_Queue =>
            Notification.Broadcast
              (Client_Notification.Leave (Get (Obj.ID)).To_JSON);

         when Unknown =>
            System_Messages.Error
              (Message => "Changing call " &
                 Obj.ID.Image & " to Unkown state!",
               Context => Context);

         when Ringing =>
            if Last_State /= Ringing then
               Notification.Broadcast
                 (Client_Notification.Call_State (Get (Obj.ID)).To_JSON);
            end if;
         when Transferring =>
            null;

      end case;
   end Change_State;

   function Contact_ID (Obj : in Instance) return Contact_Identifier is
   begin
      return Obj.Contact_ID;
   end Contact_ID;

   ------------------------
   -- Create_And_Insert  --
   ------------------------

   procedure Create_And_Insert
     (Inbound         : in Boolean;
      ID              : in Identification;
      Reception_ID    : in Reception_Identifier;
      Extension       : in String := "";
      From_Extension  : in String := "";
      Assigned_To     : in User_Identifier := Model.Null_User_Identifier)

   is
      Call : constant Instance :=
               (ID              => ID,
                Inbound         => Inbound,
                State           => Unknown,
                Is_Call         => False,
                Reception_ID    => Reception_ID,
                Greeting_Played => <>,
                Locked          => <>,
                Assigned_To     => Assigned_To,
                Contact_ID      => <>,
                Extension       => To_Unbounded_String (Extension),
                From_Extension  => To_Unbounded_String (From_Extension),
                Arrived         => Current_Time,
                B_Leg           => Null_Identification);
   begin
      Call_List.Insert (Item => Call);
   end Create_And_Insert;

   function Extension (Obj : in Instance) return String is
   begin
      return To_String (Obj.Extension);
   end Extension;

   function From_Extension (Obj : in Instance) return String is
   begin
      return To_String (Obj.From_Extension);
   end From_Extension;

   -----------
   --  Get  --
   -----------

   function Get (Call : Identification) return Instance is
   begin
      if not Call_List.Contains (Call) then
         raise Not_Found;
      end if;

      return Call_List.Get (Call);
   end Get;

   function Greeting_Played (Obj : in Instance) return Boolean is
   begin
      return Obj.Greeting_Played;
   end Greeting_Played;

   function Has (ID : Identification) return Boolean is
   begin
      return Call_List.Contains (ID);
   end Has;

   ----------
   --  ID  --
   ----------

   function ID (Obj : in Instance) return Identification is
   begin
      return Obj.ID;
   end ID;

   ---------------
   --  Inbound  --
   ---------------

   function Inbound (Obj : in Instance) return Boolean is
   begin
      return Obj.Inbound;
   end Inbound;

   function Is_Call (Obj : in Instance) return Boolean is
   begin
      return Obj.Is_Call;
   end Is_Call;

   procedure Link (ID_1 : in Identification;
                   ID_2 : in Identification) is
      --  Context : constant String := Package_Name & ".Link";
   begin
      Call_List.Link (ID_1, ID_2);
   end Link;

   ------------
   --  List  --
   ------------

   function List return GNATCOLL.JSON.JSON_Value is
   begin
      return Call_List.To_JSON;
   end List;

   ------------------
   --  List_Empty  --
   ------------------

   function List_Empty return Boolean is
   begin
      return Call_List.Empty;
   end List_Empty;

   procedure Lock (Obj : in Instance) is
   begin
      Notification.Broadcast
        (Client_Notification.Call_Lock
           (Get (Call => Obj.ID)).To_JSON);
      Call_List.Set_Locked (ID     => Obj.ID,
                            Locked => True);
   end Lock;

   --------------------
   --  Mark_As_Call  --
   --------------------

   procedure Mark_As_Call (Obj : in Instance) is
   begin
      Call_List.Set_Call (ID     => Obj.ID,
                          Is_Call => True);
   end Mark_As_Call;

   ---------------------------
   --  Null_Identification  --
   ---------------------------

   function Null_Identification return Identification is
   begin
      return ESL.UUID.Null_UUID;
   end Null_Identification;

   ---------------------
   --  Null_Instance  --
   ---------------------

   function Null_Instance return Instance is
   begin
      return (ID              => Null_Identification,
              State           => States'First,
              Inbound         => False,
              Is_Call         => False,
              Locked          => True,
              Greeting_Played => <>,
              Reception_ID    => <>,
              Contact_ID      => <>,
              Assigned_To     => <>,
              Extension       => Null_Unbounded_String,
              From_Extension  => Null_Unbounded_String,
              B_Leg           => Null_Identification,
              Arrived         => Common.Null_Time);
   end Null_Instance;

   -----------------
   --  Other_Leg  --
   ------------------

   function Other_Leg (Call : Instance) return Identification is
   begin
      if Call.Inbound then
         return Call.ID;
      else
         return Call.B_Leg;
      end if;
   end Other_Leg;

   -------------------
   --  Queue_Count  --
   -------------------

   function Queue_Count return Natural is
   begin
      return Call_List.Queued;
   end Queue_Count;

   -------------------
   --  Queue_Empty  --
   -------------------

   function Queue_Empty return Boolean is
   begin
      if Call_List.Empty then
         return True;
      else
         return Call_List.Queued > 0;
      end if;
   end Queue_Empty;

   --------------------
   --  Queued_Calls  --
   --------------------

   function Queued_Calls return GNATCOLL.JSON.JSON_Value is
   begin
      return Call_List.To_JSON (Only_Queued => True);
   end Queued_Calls;

   --------------------
   --  Reception_ID  --
   --------------------

   function Reception_ID (Obj : in Instance) return
     Reception_Identifier is
   begin
      return Obj.Reception_ID;
   end Reception_ID;

   ---------------
   --  Release  --
   ---------------

   procedure Release (Call : in Model.Call.Instance) is
   begin
      --  Check if the call is assigned.
      if Call.Assigned_To /= Model.User.Null_Identification then
         Call_List.Release (Call);
      end if;
   end Release;

   -------------------------------
   --  Set_Outbound_Parameters  --
   -------------------------------

   procedure Set_Outbound_Parameters
        (Item : in Instance;
         R_ID : in Reception_Identifier;
         C_ID : in Contact_Identifier;
         U_ID : in Model.User_Identifier) is

      Context : constant String := Package_Name & ".Set_Outbound_Parameters";

   begin
      System_Messages.Debug
        (Message =>
           "R_ID:" & R_ID'Img & " " &
           "C_ID:" & C_ID'Img & " " &
           "U_ID:" & U_ID'Img,
        Context => Context);

      Call_List.Set_Outbound_Parameters (Item => Item,
                                         R_ID => R_ID,
                                         C_ID => C_ID,
                                         U_ID => U_ID);
   end Set_Outbound_Parameters;

   ------------------------
   --  Set_Reception_ID  --
   ------------------------

   procedure Set_Reception_ID (Obj  : in Instance;
                               R_ID : in Reception_Identifier) is
      Context : constant String := Package_Name & ".Set_Reception_ID";
   begin
      System_Messages.Debug
        ("Setting Reception ID of call " & Obj.ID.Image & " to" & R_ID'Img,
         Context => Context);

      Call_List.Set_Reception (Obj.ID, R_ID);
   end Set_Reception_ID;

   -------------
   --  State  --
   -------------

   function State (Obj : in Instance) return States is
   begin
      return Obj.State;
   end State;

   ---------------
   --  To_JSON  --
   ---------------

   function To_JSON (Obj : in Instance) return GNATCOLL.JSON.JSON_Value is
      use Ada.Characters.Handling;
      use GNATCOLL.JSON;

      Value : constant JSON_Value := Create_Object;
      Call  : Instance renames Obj;
   begin
      if Call.ID /= Null_Identification then
         Value.Set_Field (View.ID, To_String (Obj.ID));
         Value.Set_Field (View.State_S, To_Lower (Call.State'Img));
         Value.Set_Field (View.B_Leg, To_String (Call.B_Leg));
         Value.Set_Field (View.Inbound, Call.Inbound);
         Value.Set_Field (View.Is_Call, Call.Is_Call);
         Value.Set_Field (View.Destination, Call.Extension);
         Value.Set_Field (View.Caller_ID, Call.From_Extension);
         Value.Set_Field (View.Greeting_Played, Call.Greeting_Played);
         Value.Set_Field (View.Reception_ID, Call.Reception_ID);
         Value.Set_Field (View.Assigned_To_S, Obj.Assigned_To);
         Value.Set_Field (View.Channel, To_String (Call.ID));
         Value.Set_Field
           (View.Arrival_Time_S, Unix_Timestamp (Call.Arrival_Time));
      else
         Value.Set_Field (View.ID, GNATCOLL.JSON.JSON_Null);
      end if;
      return Value;
   end To_JSON;

   -----------------
   --  To_String  --
   -----------------

   function To_String (Item : in Identification) return String is
      use Ada.Strings;

      Value : String renames Item.Image;
   begin
      return Ada.Strings.Fixed.Trim (Source => Value,
                                     Side   => Left);
   end To_String;

   --------------
   --  Unlink  --
   --------------

   procedure Unlink (ID : in Identification) is
   begin
      Call_List.Unlink (ID);
   end Unlink;

   --------------
   --  Unlock  --
   --------------

   procedure Unlock (Obj : in Instance) is
   begin
      Notification.Broadcast
        (Client_Notification.Call_Unlock
           (Get (Call => Obj.ID)).To_JSON);
      Call_List.Set_Locked (ID     => Obj.ID,
                            Locked => False);
   end Unlock;

   -------------
   --  Value  --
   -------------

   function Value (Item : in String) return Identification is
   begin
      return ESL.UUID.Create (Item => Item);
   exception
      when Constraint_Error =>
         raise Invalid_ID with Item;
   end Value;

   -----------------
   --  Call_List  --
   -----------------

   protected body Call_List is

      -------------------
      --  Assign_Call  --
      -------------------

      procedure Assign_Call
        (To   : in     Model.User_Identifier;
         Call :    out Model.Call.Instance;
         ID   : in     Model.Call.Identification :=
           Model.Call.Null_Identification) is
         use Call_Storage;

         Context : constant String := Package_Name & ".Call_List.Assign_Call";

         procedure Assign (Key  : in     Identification;
                           Call : in out Instance);

         function Available_For_User
           (Item : in Model.Call.Instance) return Boolean;

         procedure Assign (Key  : in     Identification;
                           Call : in out Instance) is
            pragma Unreferenced (Key);
         begin
            System_Messages.Debug (Message => "Assigning call "&
                                     " to user." &
                                     To'Img,
                                   Context => Context);
            Call.Assigned_To := To;
            System_Messages.Debug (Message => "Assigned call "&
                                     " to user." &
                                     Call.Assigned_To'Img,
                                   Context => Context);
         end Assign;

         function Available_For_User
           (Item : in Model.Call.Instance) return Boolean is
         begin
            return Item.Assigned_To = Model.Null_User_Identifier or
                   Item.Assigned_To = To;
         end Available_For_User;

      begin
         if ID /= Model.Call.Null_Identification then
            declare
               Prospected_Call : Model.Call.Instance renames List.Element (ID);
            begin
               if not Available_For_User (Prospected_Call) then
                  raise Not_Available with "Call is not available for to user";
               elsif
                     Prospected_Call.Is_Call      and
                 not Prospected_Call.Locked
               then
                  Call_List.Update (Prospected_Call.ID, Assign'Access);
                  --  Return the updated element.
                  Call := List.Element (Prospected_Call.ID);
                  return;
               end if;
            end;
         end if;

         System_Messages.Debug (Message => "Finding unspecified call.",
                                Context => Context);

         declare
            C : Cursor := List.First;
         begin
            while C /= No_Element loop
               declare
                  Prospected_Call : Model.Call.Instance renames Element (C);
               begin
                  if    Available_For_User (Prospected_Call) and
                        Prospected_Call.Is_Call              and
                        Prospected_Call.Inbound              and
                        Prospected_Call.State /= Parked      and
                    not Prospected_Call.Locked
                  then
                     Call_List.Update (Prospected_Call.ID, Assign'Access);
                     --  Return the updated element.
                     Call := List.Element (Prospected_Call.ID);
                     return;
                  end if;
               end;
               Next (C);
            end loop;
         end;

         System_Messages.Debug (Message => "No call found.",
                                Context => Context);
         raise Not_Found;
      exception
         when Constraint_Error =>
            raise Not_Found with ID.Image;

      end Assign_Call;

      --------------------
      --  Change_State  --
      --------------------

      procedure Change_State (ID        : in Identification;
                              New_State : in States) is
         procedure Update (Key     : in     Identification;
                           Element : in out Instance);

         procedure Update (Key     : in     Identification;
                           Element : in out Instance) is
            pragma Unreferenced (Key);
         begin
            Element.State := New_State;

            if New_State = Queued then
               Element.Greeting_Played := True;
            end if;

         end Update;
      begin
         Call_List.Update (ID, Update'Access);
      end Change_State;

      ----------------
      --  Contains  --
      ----------------

      function Contains (ID : in Identification)
                         return Boolean is
      begin
         return List.Contains (ID);
      end Contains;

      -------------
      --  Empty  --
      -------------

      function Empty return Boolean is
      begin
         return List.Is_Empty;
      end Empty;

      -----------
      --  Get  --
      -----------

      function Get (ID : in Identification) return Instance is
      begin
         if not List.Contains (ID) then
            raise Not_Found;
         else
            return List.Element (ID);
         end if;
      end Get;

      --------------
      --  Insert  --
      --------------

      procedure Insert (Item : Instance) is
      begin
         if Item.ID = Null_Identification then
            raise Constraint_Error;
         end if;

         List.Insert (Key      => Item.ID,
                      New_Item => Item);
         System_Messages.Debug
           (Message => "Inserted call" & Item.ID.Image,
            Context => Package_Name & "Call_List.Insert");
      exception
         when Constraint_Error =>
            raise Constraint_Error with "ID" & To_String (Item.ID);
      end Insert;

      ------------
      --  Link  --
      ------------

      procedure Link (ID_1, ID_2 : in Identification) is
         procedure Update (Key     : in     Identification;
                           Element : in out Instance);

         procedure Update (Key     : in     Identification;
                           Element : in out Instance) is
         begin
            if Key = ID_1 then
               Element.B_Leg := ID_2;
            else
               Element.B_Leg := ID_1;
            end if;
         end Update;
      begin
         Call_List.Update (ID_1, Update'Access);
         Call_List.Update (ID_2, Update'Access);
      end Link;

      --------------
      --  Queued  --
      --------------

      function Queued return Natural is
      begin
         return Number_Queued;
      end Queued;

      ---------------
      --  Release  --
      ---------------

      procedure Release (Call : in Model.Call.Instance) is

         procedure Do_Release (Key  : in     Identification;
                               Call : in out Model.Call.Instance);

         procedure Do_Release (Key  : in     Identification;
                               Call : in out Model.Call.Instance) is
            pragma Unreferenced (Key);
         begin
            Call.Assigned_To := Model.User.Null_Identification;
         end Do_Release;
      begin
         Model.User.Assign_Call (User_ID => Call.Assigned_To,
                                 Call_ID => Model.Call.Null_Identification);
         Call_List.Update (Call.ID, Do_Release'Access);
      end Release;

      --------------
      --  Remove  --
      --------------

      procedure Remove (ID : in Identification) is
      begin
         List.Delete (Key => ID);
      exception
         when Constraint_Error =>
            raise Not_Found with " call " & To_String (ID);
      end Remove;

      ----------------
      --  Set_Call  --
      ----------------

      procedure Set_Call (ID      : in Identification;
                          Is_Call : in Boolean) is
         procedure Set_Is_Call (Key     : in     Identification;
                           Element : in out Instance);

         procedure Set_Is_Call (Key     : in     Identification;
                                Element : in out Instance) is
            pragma Unreferenced (Key);
         begin
            Element.Is_Call := Is_Call;
         end Set_Is_Call;
      begin
         Call_List.Update (ID, Set_Is_Call'Access);
      end Set_Call;

      ------------------
      --  Set_Locked  --
      ------------------

      procedure Set_Locked (ID     : in Identification;
                            Locked : in Boolean) is
         procedure Set_Lock (Key     : in     Identification;
                           Element : in out Instance);

         procedure Set_Lock (Key     : in     Identification;
                             Element : in out Instance) is
            pragma Unreferenced (Key);
         begin
            Element.Locked := Locked;
         end Set_Lock;
      begin
         Call_List.Update (ID, Set_Lock'Access);
      end Set_Locked;

      procedure Set_Outbound_Parameters
        (Item : in Instance;
         R_ID : in Reception_Identifier;
         C_ID : in Contact_Identifier;
         U_ID : in Model.User_Identifier) is
         procedure Update (Key     : in     Identification;
                           Element : in out Instance);

         procedure Update (Key     : in     Identification;
                           Element : in out Instance) is
            pragma Unreferenced (Key);
         begin
            Element.Assigned_To  := U_ID;
            Element.Contact_ID   := C_ID;
            Element.Reception_ID := R_ID;
         end Update;
      begin
         Call_List.Update (Item.ID, Update'Access);
      end Set_Outbound_Parameters;

      ---------------------
      --  Set_Reception  --
      ---------------------

      procedure Set_Reception (ID   : in Identification;
                               R_ID : in Reception_Identifier) is
         procedure Update (Key     : in     Identification;
                           Element : in out Instance);

         procedure Update (Key     : in     Identification;
                           Element : in out Instance) is
            pragma Unreferenced (Key);
         begin
            Element.Reception_ID := R_ID;
         end Update;
      begin
         Call_List.Update (ID, Update'Access);
      end Set_Reception;

      ---------------
      --  To_JSON  --
      ---------------

      function To_JSON (Only_Queued : Boolean := False)
                        return GNATCOLL.JSON.JSON_Value is
         use GNATCOLL.JSON;
         use Call_Storage;
         Value     : JSON_Value := Create_Object;
         JSON_List : JSON_Array;
         Root      : constant JSON_Value := Create_Object;
      begin
         declare
            C : Cursor := List.First;
         begin
            while C /= No_Element loop
               if not Only_Queued then
                  Value := Element (C).To_JSON;
                  Append (JSON_List, Value);
               elsif Only_Queued and then Element (C).State = Queued then
                  Value := Element (C).To_JSON;
                  Append (JSON_List, Value);
               end if;
               Next (C);
            end loop;
         end;

         Root.Set_Field ("calls", JSON_List);
         return Root;
      end To_JSON;

      --------------
      --  Unlink  --
      --------------

      procedure Unlink (ID : in Identification) is
         procedure Update (Key     : in     Identification;
                           Element : in out Instance);

         procedure Update (Key     : in     Identification;
                           Element : in out Instance) is
            pragma Unreferenced (Key);
         begin
            Element.B_Leg := Null_Identification;
         end Update;
      begin
         --  TODO: Update B-leg.
         Call_List.Update (ID, Update'Access);
      end Unlink;

      --------------
      --  Update  --
      --------------

      procedure Update (ID    : in Identification;
                        Process : not null access procedure
                          (Key     : in     Identification;
                           Element : in out Instance)) is
      begin
         List.Update_Element (Position => List.Find (ID),
                              Process  => Process);
      end Update;
   end Call_List;
end Model.Call;
