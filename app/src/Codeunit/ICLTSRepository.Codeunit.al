/// <summary>
/// Central data-access layer for all ICLTS tables.
/// No other application-layer codeunit may access ICLTS tables directly.
/// </summary>
codeunit 50301 "ICLTS Repository"
{
    Access = Public;

    // ──────────────────────────────────────────────────────────────────────────
    // ICLTS Tracking Buffer
    // ──────────────────────────────────────────────────────────────────────────

    /// <summary>
    /// Inserts one tracking-buffer line representing a single lot/serial assignment
    /// on an outbound IC sales line.
    /// </summary>
    /// <param name="ICPartnerCode">The IC partner the document is addressed to.</param>
    /// <param name="OutboundDocNo">The sales order document number in the sending company.</param>
    /// <param name="OutboundLineNo">The sales line number.</param>
    /// <param name="ItemNo">The item number.</param>
    /// <param name="VariantCode">The item variant code (may be blank).</param>
    /// <param name="LotNo">The lot number (may be blank).</param>
    /// <param name="SerialNo">The serial number (may be blank).</param>
    /// <param name="QuantityBase">The quantity in the item's base unit of measure (absolute value).</param>
    /// <param name="Description">Free-text description copied from the reservation entry.</param>
    procedure InsertTrackingBuffer(
        ICPartnerCode: Code[20];
        OutboundDocNo: Code[20];
        OutboundLineNo: Integer;
        ItemNo: Code[20];
        VariantCode: Code[10];
        LotNo: Code[50];
        SerialNo: Code[50];
        QuantityBase: Decimal;
        Description: Text[100])
    var
        TrackingBuffer: Record "ICLTS Tracking Buffer";
    begin
        TrackingBuffer.Init();
        TrackingBuffer."IC Partner Code" := ICPartnerCode;
        TrackingBuffer."Outbound Doc. No." := OutboundDocNo;
        TrackingBuffer."Outbound Line No." := OutboundLineNo;
        TrackingBuffer."Item No." := ItemNo;
        TrackingBuffer."Variant Code" := VariantCode;
        TrackingBuffer."Lot No." := LotNo;
        TrackingBuffer."Serial No." := SerialNo;
        TrackingBuffer."Quantity (Base)" := Abs(QuantityBase);
        TrackingBuffer."Description" := Description;
        TrackingBuffer."Created At" := CurrentDateTime();
        TrackingBuffer.Insert(true);
    end;

    /// <summary>
    /// Filters the tracking-buffer to unprocessed lines for the given IC partner and
    /// outbound document number, positions the cursor on the first record, and returns
    /// whether at least one matching line exists.  The caller may iterate the result set
    /// using <c>TrackingBuffer.Next()</c>.
    /// </summary>
    /// <param name="TrackingBuffer">Output — the filtered, positioned record set (caller iterates it).</param>
    /// <param name="ICPartnerCode">The IC partner filter.</param>
    /// <param name="OutboundDocNo">The outbound document number filter.</param>
    /// <returns>True when one or more unprocessed lines exist; false when the set is empty.</returns>
    procedure GetPendingTrackingLines(
        var TrackingBuffer: Record "ICLTS Tracking Buffer";
        ICPartnerCode: Code[20];
        OutboundDocNo: Code[20]): Boolean
    begin
        TrackingBuffer.Reset();
        TrackingBuffer.SetRange("IC Partner Code", ICPartnerCode);
        TrackingBuffer.SetRange("Outbound Doc. No.", OutboundDocNo);
        TrackingBuffer.SetRange("Processed", false);
        exit(TrackingBuffer.FindSet());
    end;

    /// <summary>
    /// Marks all tracking-buffer lines for the given IC partner and outbound document
    /// as processed and stamps the processing timestamp.
    /// </summary>
    /// <param name="ICPartnerCode">The IC partner filter.</param>
    /// <param name="OutboundDocNo">The outbound document number filter.</param>
    procedure MarkTrackingLinesProcessed(ICPartnerCode: Code[20]; OutboundDocNo: Code[20])
    var
        TrackingBuffer: Record "ICLTS Tracking Buffer";
    begin
        TrackingBuffer.SetRange("IC Partner Code", ICPartnerCode);
        TrackingBuffer.SetRange("Outbound Doc. No.", OutboundDocNo);
        TrackingBuffer.SetRange("Processed", false);
        if TrackingBuffer.FindSet(true) then
            repeat
                TrackingBuffer."Processed" := true;
                TrackingBuffer."Processed At" := CurrentDateTime();
                TrackingBuffer.Modify(false);
            until TrackingBuffer.Next() = 0;
    end;

    /// <summary>
    /// Deletes processed tracking-buffer lines older than the specified number of days.
    /// Called during routine maintenance to prevent unbounded table growth.
    /// </summary>
    /// <param name="RetentionDays">Lines processed more than this many days ago are deleted.</param>
    procedure DeleteProcessedTrackingLines(RetentionDays: Integer)
    var
        TrackingBuffer: Record "ICLTS Tracking Buffer";
        CutoffDateTime: DateTime;
    begin
        CutoffDateTime := CreateDateTime(CalcDate('<-' + Format(RetentionDays) + 'D>', Today()), 0T);
        TrackingBuffer.SetRange("Processed", true);
        TrackingBuffer.SetFilter("Processed At", '<%1', CutoffDateTime);
        TrackingBuffer.DeleteAll(false);
    end;

    // ──────────────────────────────────────────────────────────────────────────
    // ICLTS Gap Log Entry
    // ──────────────────────────────────────────────────────────────────────────

    /// <summary>
    /// Inserts a new gap-log entry recording an error, warning, or success event.
    /// </summary>
    /// <param name="EntryType">The severity of the log entry.</param>
    /// <param name="ModuleCode">The module that generated the entry.</param>
    /// <param name="Context">Short description of the operation context (≤ 250 chars).</param>
    /// <param name="ErrorText">Full error or informational message (≤ 2 048 chars).</param>
    procedure InsertGapLogEntry(
        EntryType: Enum "ICLTS Log Entry Type";
        ModuleCode: Enum "ICLTS Module Code";
        Context: Text[250];
        ErrorText: Text[2048])
    var
        GapLogEntry: Record "ICLTS Gap Log Entry";
    begin
        GapLogEntry.Init();
        GapLogEntry."Entry Type" := EntryType;
        GapLogEntry."Module Code" := ModuleCode;
        GapLogEntry."Context" := Context;
        GapLogEntry."Error Text" := ErrorText;
        GapLogEntry."Created At" := CurrentDateTime();
        GapLogEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(GapLogEntry."User ID"));
        GapLogEntry.Insert(false);
    end;

    /// <summary>
    /// Deletes gap-log entries older than the specified number of days.
    /// </summary>
    /// <param name="RetentionDays">Entries older than this many days are removed.</param>
    procedure DeleteOldGapLogEntries(RetentionDays: Integer)
    var
        GapLogEntry: Record "ICLTS Gap Log Entry";
        CutoffDateTime: DateTime;
    begin
        CutoffDateTime := CreateDateTime(CalcDate('<-' + Format(RetentionDays) + 'D>', Today()), 0T);
        GapLogEntry.SetFilter("Created At", '<%1', CutoffDateTime);
        GapLogEntry.DeleteAll(false);
    end;
}
