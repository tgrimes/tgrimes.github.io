+++
# Display name
name = "Tyler Grimes"

# Is this the primary user of the site?
superuser = true

# Role/position
role = "Ph.D. Candidate in Biostatistics"

# Organizations/Affiliations
#   Separate multiple entries with a comma, using the form: `[ {name="Org1", url=""}, {name="Org2", url=""} ]`.
organizations = [ { name = "University of Florida", url = "" } ]

# Short bio (displayed in user profile at end of posts)
bio = "My research interests are in the development of statistical methods for high-dimensional data with applications in genomics."

# Enter email to display Gravatar (if Gravatar enabled in Config)
email = "tyler.grimes@ufl.edu"

# List (academic) interests or hobbies
interests = [
  "Statistical methods for -omics data",
  "Graphical models and differential network analysis",
  "Predictive models and model validation",
  "Sparse estimation",
  "Statistical computing"
]

# List qualifications (such as academic degrees)
[[education.courses]]
  course = "Ph.D. in Biostatistics"
  institution = "University of Florida"
  year = 2020

[[education.courses]]
  course = "M.S. in Mathematics (concentration in Statistics)"
  institution = "University of North Florida"
  year = 2016

[[education.courses]]
  course = "B.S. in Mathematics (minor in Computer Science)"
  institution = "University of Central Florida"
  year = 2014

# Social/Academic Networking
#
# Icon pack "fab" includes the following social network icons:
#
#   twitter, weibo, linkedin, github, facebook, pinterest, google-plus,
#   youtube, instagram, soundcloud
#
#   For email icon, use "fas" icon pack, "envelope" icon, and
#   "mailto:your@email.com" as the link.
#
#   Full list: https://fontawesome.com/icons
#
# Icon pack "ai" includes the following academic icons:
#
#   cv, google-scholar, arxiv, orcid, researchgate, mendeley
#
#   Full list: https://jpswalsh.github.io/academicons/

[[social]]
  icon = "envelope"
  icon_pack = "fas"
  link = "mailto:tyler.grimes@ufl.edu"  # For a direct email link, use "mailto:test@example.org".

[[social]]
  icon = "twitter"
  icon_pack = "fab"
  link = "https://twitter.com/TylerLGrimes"

[[social]]
  icon = "google-scholar"
  icon_pack = "ai"
  link = "https://scholar.google.co.uk/citations?user=ROPfgIEAAAAJ&hl=en&oi=sra"

[[social]]
  icon = "github"
  icon_pack = "fab"
  link = "https://github.com/tgrimes"

# Link to a PDF of your resume/CV from the About widget.
# To enable, copy your resume/CV to `static/files/cv.pdf` and uncomment the lines below.
[[social]]
  icon = "cv"
  icon_pack = "ai"
  link = "files/cv.pdf"

+++

I'm a Ph.D. Candidate at the Univeristy of Florida. My research interests include the development of statistical methodology for -omics data. 

Recent work has focused on RNA-seq data (transcriptomics), with methods in the areas of survival analysis, predictive modelling, and graphical models. How might gene expression profiles be used to predict patient survival times? How do gene-gene associations differ in high-risk vs. low-risk patients, and what clues do these differences leave us about the underlying disease? Future work will delve into methodology for single-cell data, which provides a much finer resolution of cellular activity. 

I prefer assessing model performance through extensive simulations over large-sample inference; the latter can be reassuring, but the former forces us to better understand the biological context (or data generating process) to which the methods are applied. Through simulations we can explore conditions to find when our models work and when they fail - this is a process that has often lead me to new insights and a deeper understanding.