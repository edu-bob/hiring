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
                                    heading => "Uploaded Document",
                                    type => "blob",
				    binary => 1,
                                },
                                {
                                    column => "size",
                                    heading => "Size of Uploaded Data",
                                    type => "text",
                                },
                                {
                                    column => "temporary",
                                    heading => "File is Temporary",
                                    type => "text",
                                },
                                ]
                    );

1;
