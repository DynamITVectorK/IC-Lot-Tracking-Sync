/// <summary>
/// Temporary buffer used to transfer item-tracking lines (lot numbers, serial numbers,
/// and quantities) from an outbound IC Sales document to the corresponding inbound
/// IC Purchase document, either within the same tenant or across tenants via API.
/// </summary>
table 50301 "ICLTS Tracking Buffer"
{
    Caption = 'ICLTS Tracking Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }
        field(10; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            DataClassification = CustomerContent;
        }
        field(11; "Outbound Doc. No."; Code[20])
        {
            Caption = 'Outbound Doc. No.';
            DataClassification = CustomerContent;
        }
        field(12; "Outbound Line No."; Integer)
        {
            Caption = 'Outbound Line No.';
            DataClassification = CustomerContent;
        }
        field(20; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = CustomerContent;
        }
        field(21; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            DataClassification = CustomerContent;
        }
        field(30; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';
            DataClassification = CustomerContent;
        }
        field(31; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
            DataClassification = CustomerContent;
        }
        field(40; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
        }
        field(50; "Description"; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(60; "Processed"; Boolean)
        {
            Caption = 'Processed';
            DataClassification = CustomerContent;
        }
        field(61; "Created At"; DateTime)
        {
            Caption = 'Created At';
            DataClassification = SystemMetadata;
        }
        field(62; "Processed At"; DateTime)
        {
            Caption = 'Processed At';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Lookup; "IC Partner Code", "Outbound Doc. No.", "Outbound Line No.", "Processed")
        {
        }
    }
}
