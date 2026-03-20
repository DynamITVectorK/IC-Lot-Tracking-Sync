/// <summary>
/// Classifies entries written to the ICLTS Gap Log.
/// </summary>
enum 50301 "ICLTS Log Entry Type"
{
    Extensible = false;

    /// <summary>The operation completed successfully.</summary>
    value(0; Success)
    {
        Caption = 'Success';
    }

    /// <summary>A warning was raised but the operation continued.</summary>
    value(1; Warning)
    {
        Caption = 'Warning';
    }

    /// <summary>An unrecoverable error occurred during the operation.</summary>
    value(2; Error)
    {
        Caption = 'Error';
    }
}
