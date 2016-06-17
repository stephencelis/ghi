def issues
	[
		{
			title: "Test Issue 1",
			des: <<EOF,
This is a test issue. Here is some random description. Some random feature is
not working. I don't know what's wrong. The os is ubuntu 16.04.
EOF

			assign: "ghitest",
			milestone: 1,
			labels: ["help-wanted", "wontfix", "bug" ]
		},
		{
			title: "Test Issue 2",
			des: <<EOF,
This is the second issue. I don't know what to write. This is a critical
confirmed bug and a feature request at the same time.
EOF

			assign: "ghitest",
			milestone: 2,
			labels: ["feature", "critical", "bug", "confirmed" ]
		},
		{
			title: "Test Issue 3",
			des: <<EOF,
I am really out of content to write.
EOF

			assign: "ghitest",
			milestone: 2,
			labels: ["critical", "help-wanted" ]
		},
		{
			title: "Test Issue 4",
			des: <<EOF,
Hello how are you??
EOF

			assign: "ghitest",
			milestone: 1,
			labels: ["bug", "confirmed" ]
		}

	]
end

def comments
	[
		"This is first test comment",
		"This is second test comment",
		"This is thrid test comment"
	]
end

def milestones
	[
		{
			title: "Milestone Title",
			des: "Milestone Discreption",
			due: "2012-04-30"
		},
		{
			title: "Milestone Title 1",
			des: "Milestone Discreption 1",
			due: "2012-04-30"
		}
	]
end
