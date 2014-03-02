# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.
%::DocumentTable = (
                    table => "document",
                    heading => "Documents",
                    columns => [
                                {
                                    column => "id",
                                    heading => "Id",
                                    type => "pk",
                                },
                                {
                                    column => "creation",
                                    heading => "Creation",
                                    type => "datetime",
                                },
                                {
                                    column => "candidate_id",
                                    heading => "Candidate",
                                    type => "fk",
                                    values => {
                                        table => \%::CandidateTable,
                                        pk => "id",
                                        label => "name",
                                    },
                                },
                                {
                                    column => "contents",
                                    heading => "Contents",
                                    type => "text",
                                },
                                {
                                    column => "filename",
                                    heading => "Filename",
                                    type => "text",
                                },
                                {
                                    column => "data",
                                    heading => "Uploaded document",
                                    type => "blob",
                                },
                                {
                                    column => "size",
                                    heading => "Size of uploaded data",
                                    type => "text",
                                },
                                {
                                    column => "temporary",
                                    heading => "File is temporary",
                                    type => "text",
                                },
                                ]
                    );

1;
