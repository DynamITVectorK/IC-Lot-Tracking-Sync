/// <summary>
/// Records errors and warnings that occur within the IC Lot Tracking Sync extension
/// without propagating exceptions to the standard BC call stack.
/// </summary>
table 50302 "ICLTS Gap Log Entry"
{
    Caption = 'ICLTS Gap Log Entry';
    DataClassification = CustomerContent;
    DrillDownPageId = "ICLTS Gap Log Entries";
    LookupPageId = "ICLTS Gap Log Entries";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }
        field(10; "Entry Type"; Enum "ICLTS Log Entry Type")
        {
            Caption = 'Entry Type';
            DataClassification = CustomerContent;
        }
        field(11; "Module Code"; Enum "ICLTS Module Code")
        {
            Caption = 'Module Code';
            DataClassification = CustomerContent;
        }
        field(20; "Context"; Text[250])
        {
            Caption = 'Context';
            DataClassification = CustomerContent;
        }
        field(21; "Error Text"; Text[2048])
        {
            Caption = 'Error Text';
            DataClassification = CustomerContent;
        }
        field(30; "Created At"; DateTime)
        {
            Caption = 'Created At';
            DataClassification = SystemMetadata;
        }
        field(31; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserPseudonymousIdentifiers;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(ByCreatedAt; "Created At")
        {
        }
        key(ByModule; "Module Code", "Entry Type", "Created At")
        {
        }
    }
}
