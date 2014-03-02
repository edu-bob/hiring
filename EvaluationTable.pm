# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.
%::EvaluationTable = (
                    table => "evaluation",
                    heading => "Evaluation Forms",
                    columns => [
                                {
                                    column => "id",
                                    heading => "Id",
                                    type => "pk",
                                },
				 {
				     column => "title",
				     heading => "Title",
				     type => "text",
                                     help => "Evaluation form title.",
				 },
                                {
                                    column => "content",
                                    heading => "Content",
                                    type => "bigtext",
                                },
                               {
                                    column => "prompt",
                                    heading => "prompt",
                                    type => "bigtext",
                                },
                                ]
                    );

1;
