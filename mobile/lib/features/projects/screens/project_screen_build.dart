part of project_screen;

extension _ProjectScreenBuild on _ProjectScreenState {
  Widget _buildProjectScreen(BuildContext context) {
    const themeColor = Color(0xFF06B6D4);

    return Consumer<ProjectProvider>(
      builder: (context, provider, child) {
        _projects = provider.projects;
        _isLoading = provider.isLoading;
        _projectLoadError = provider.errorMessage;

        return ListenableBuilder(
          listenable: Listenable.merge(
              [ThemeService.isDarkMode, LocaleService.languageCode]),
          builder: (context, child) {
            final isDark = ThemeService.isDarkMode.value;
            final textColor = ThemeService.getTextColor(isDark);
            final captionColor = ThemeService.getCaptionColor(isDark);
            final visibleProjectModels = _visibleProjects;

            return Scaffold(
          backgroundColor: Colors.transparent,
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                // ── Header ──────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TEAM COLLABORATION',
                            style: TextStyle(
                              color: captionColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Team Projects',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    PremiumButton.icon(
                      onPressed: _showCreateProjectDialog,
                      icon: Icons.add,
                      label: 'New',
                      backgroundColor: themeColor,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // ── Search / Filter ──────────────────────
                ProjectSearchBar(
                  controller: _projectSearchController,
                  onChanged: (value) {
                    _updateProjectState(() => _projectSearchQuery = value);
                  },
                  onFilterTap: _showProjectFilterBottomSheet,
                ),
                const SizedBox(height: 12),
                ProjectSummary(
                  totalProjects: _projects.length,
                  activeProjects: _activeProjectCount,
                  attentionProjects: _attentionProjects.length,
                ),
                const SizedBox(height: 14),
                ProjectTabs(
                  tabs: _projectFilterOptions,
                  selectedTab: _projectTab,
                  onChanged: (tab) {
                    _updateProjectState(() => _projectTab = tab);
                  },
                ),
                const SizedBox(height: 14),
                // ── Content ──────────────────────────────
                Expanded(
                  child: _buildBody(
                    context,
                    themeColor: themeColor,
                    textColor: textColor,
                    captionColor: captionColor,
                    visibleProjectModels: visibleProjectModels,
                  ),
                ),
              ],
            ),
          ),
        );
          },
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required Color themeColor,
    required Color textColor,
    required Color captionColor,
    required List<ProjectModel> visibleProjectModels,
  }) {
    if (_isLoading) {
      return _buildSkeletonList();
    }

    if (_projectLoadError != null) {
      return _buildErrorState(
        themeColor: themeColor,
        captionColor: captionColor,
      );
    }

    if (_projects.isEmpty) {
      return _buildFirstRunEmpty(
        themeColor: themeColor,
        textColor: textColor,
        captionColor: captionColor,
      );
    }

    if (visibleProjectModels.isEmpty) {
      return _buildNoMatchEmpty(captionColor: captionColor);
    }

    return RefreshIndicator(
      onRefresh: _loadProjects,
      color: themeColor,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _sectionTitleForTab(_projectTab),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${visibleProjectModels.length}/${_projects.length}',
                  style: TextStyle(
                    color: captionColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          ...visibleProjectModels.asMap().entries.map((entry) {
            final project = entry.value;
            return FadeInSlide(
              delayMs: entry.key * 50,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: ProjectCardV2(
                  project: project,
                  onTap: () => _showProjectDetails(project),
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _sectionTitleForTab(String tab) {
    switch (tab) {
      case 'Mine':
        return 'My Projects';
      case 'Shared':
        return 'Shared With Me';
      case 'Archived':
        return 'Archived';
      default:
        return 'All Projects';
    }
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: 12.0),
        child: ShimmerLoading(
          width: double.infinity,
          height: 132,
          borderRadius: 18,
        ),
      ),
    );
  }

  Widget _buildErrorState({
    required Color themeColor,
    required Color captionColor,
  }) {
    return FadeInSlide(
      delayMs: 100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 54,
              color: Colors.redAccent.withValues(alpha: 0.75),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _projectLoadError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: captionColor, fontSize: 13),
              ),
            ),
            const SizedBox(height: 14),
            PremiumButton.icon(
              onPressed: _loadProjects,
              icon: Icons.refresh_rounded,
              label: 'Retry',
              backgroundColor: themeColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFirstRunEmpty({
    required Color themeColor,
    required Color textColor,
    required Color captionColor,
  }) {
    return FadeInSlide(
      delayMs: 100,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('📁', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 14),
              Text(
                'No projects yet',
                style: TextStyle(
                  color: textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Create your first project to start tracking work, milestones and collaborators.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: captionColor,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              PremiumButton.icon(
                onPressed: _showCreateProjectDialog,
                icon: Icons.add_rounded,
                label: 'Create project',
                backgroundColor: themeColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoMatchEmpty({required Color captionColor}) {
    return FadeInSlide(
      delayMs: 100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              'No projects match your filters',
              style: TextStyle(color: captionColor, fontSize: 14),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: _clearProjectFilters,
              child: const Text('Clear filters'),
            ),
          ],
        ),
      ),
    );
  }
}
