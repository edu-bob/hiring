# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.
use ActionTable;
use ActionCategoryTable;
use AuditTable;
use CandidateTable;
use CategoryCountTable;
use CcTable;
use CommentTable;
use CronTable;
use DepartmentTable;
use DocumentTable;
use EvaluationTable;
use OpeningEvaluationTable;
use FrontlinkTable;
use InterviewPersonTable;
use InterviewSlotTable;
use InterviewTable;
use KeywordTable;
use OpeningTable;
use ParamTable;
use RatingTable;
use RecruiterTable;
use SuggestionTable;
use TempDirTable;
use TemplateTable;
use UserTable;


@::Tables = (
    \%::ActionTable,
    \%::ActionCategoryTable,
    \%::AuditTable,
    \%::CandidateTable,
    \%::CategoryCountTable,
    \%::CcTable,
    \%::CommentTable,
    \%::CronTable,
    \%::DepartmentTable,
    \%::DocumentTable,
    \%::EvaluationTable,
    \%::FrontlinkTable,
    \%::InterviewPersonTable,
    \%::InterviewSlotTable,
    \%::InterviewTable,
    \%::KeywordTable,
    \%::OpeningTable,
    \%::OpeningEvaluationTable,
    \%::ParamTable,
    \%::RatingTable,
    \%::RecruiterTable,
    \%::SuggestionTable,
    \%::TempDirTable,
    \%::TemplateTable,
    \%::UserTable,
    );
